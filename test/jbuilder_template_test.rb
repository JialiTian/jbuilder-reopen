require "test_helper"
require "action_view/testing/resolvers"

class JbuilderTemplateTest < ActiveSupport::TestCase
  POST_PARTIAL = <<-JBUILDER
    json.extract! post, :id, :body
    json.author do
      first_name, last_name = post.author_name.split(nil, 2)
      json.first_name first_name
      json.last_name last_name
    end
  JBUILDER

  COLLECTION_PARTIAL = <<-JBUILDER
    json.extract! collection, :id, :name
  JBUILDER

  RACER_PARTIAL = <<-JBUILDER
    json.extract! racer, :id, :name
  JBUILDER

  PARTIALS = {
    "_partial.json.jbuilder"      => "json.content content",
    "_post.json.jbuilder"         => POST_PARTIAL,
    "racers/_racer.json.jbuilder" => RACER_PARTIAL,
    "_collection.json.jbuilder"   => COLLECTION_PARTIAL,

    # Ensure we find only Jbuilder partials from within Jbuilder templates.
    "_post.html.erb" => "Hello world!"
  }

  AUTHORS = [ "David Heinemeier Hansson", "Pavel Pravosud" ].cycle
  POSTS   = (1..10).collect { |i| Post.new(i, "Post ##{i}", AUTHORS.next) }

  setup { Rails.cache.clear }

  test "reopen array" do
    code = <<-JBUILDER
      json.cache! "cache-key" do
        json.posts @posts, partial: "post", as: :post
      end
      json.reopen! ["posts"] do |post|
        json.title ("title " + post["id"].to_s)
      end
    JBUILDER
    result = render(code, posts: POSTS)
    assert_equal "title 1", result["posts"][0]["title"]
  end

  test "reopen nested hash" do
    code = <<-JBUILDER
      json.cache! "cache-key" do
        json.posts @posts, partial: "post", as: :post
      end
      json.reopen! ["posts"] do |post|
        json.title post["body"]
      end
      json.reopen! ["posts", "author"] do |author|
        json.middle_name author["first_name"]
      end
    JBUILDER
    result = render(code, posts: POSTS)
    assert_equal "Post #1", result["posts"][0]["title"]
    assert_equal 1, result["posts"][0]["id"]
    assert_equal "Post #1", result["posts"][0]["body"]
    assert_equal "David", result["posts"][2]["author"]["first_name"]
    assert_equal "Heinemeier Hansson", result["posts"][2]["author"]["last_name"]
    assert_equal "David", result["posts"][2]["author"]["middle_name"]
    assert_equal "Pavel", result["posts"][5]["author"]["middle_name"]
  end

  test "reopen nested reopen" do
    code = <<-JBUILDER
      json.cache! "cache-key" do
        json.posts @posts, partial: "post", as: :post
      end
      json.reopen! ["posts"] do |post|
        json.title post["body"]
        json.reopen! ["author"] do |author|
          json.middle_name author["first_name"]
        end
      end
    JBUILDER
    result = render(code, posts: POSTS)
    assert_equal "Post #1", result["posts"][0]["title"]
    assert_equal 1, result["posts"][0]["id"]
    assert_equal "Post #1", result["posts"][0]["body"]
    assert_equal "David", result["posts"][2]["author"]["first_name"]
    assert_equal "Heinemeier Hansson", result["posts"][2]["author"]["last_name"]
    assert_equal "David", result["posts"][2]["author"]["middle_name"]
    assert_equal "Pavel", result["posts"][5]["author"]["middle_name"]
  end

  test "reopen nested array" do
    code = <<-JBUILDER
      json.cache! "cache-key" do
        json.authors ["David Heinemeier Hansson", "Pavel Pravosud"] do |author|
          json.name author
          json.posts @posts, partial: "post", as: :post
        end
      end
      json.reopen! ["authors", "posts"] do |_post|
        json.title "test"
        json.body nil
      end
    JBUILDER
    result = render(code, posts: POSTS)
    assert_equal "test", result["authors"][0]["posts"][2]["title"]
    assert_nil result["authors"][0]["posts"][2]["body"]
  end

  test "raise error if change data type has been overrided" do
    code = <<-JBUILDER
      json.cache! "cache-key" do
        json.posts @posts, partial: "post", as: :post
      end
      json.reopen! ["posts", "body"] do |_body|
        json.title "test"
      end
    JBUILDER
    result = render(code, posts: POSTS)
    assert_nil result["posts"][0]["title"]
    assert_equal "Post #1", result["posts"][0]["body"]
  end

  test "do nothing if anchor target is not found" do
    code = <<-JBUILDER
      json.cache! "cache-key" do
        json.posts @posts, partial: "post", as: :post
      end
      json.reopen! ["posts", "title"] do |_body|
        json.title "test"
      end
    JBUILDER
    result = render(code, posts: POSTS)
    assert_equal false, result["posts"][0].key?("title")
    assert_equal "Post #1", result["posts"][0]["body"]
  end

  test "do nothing if anchor target is missing" do
    discussions = [
      {
        title: "Discussion 1",
        posts: POSTS 
      },
      {
        title: "Discussion 2",
        posts: [] 
      }
    ]
    code = <<-JBUILDER
      json.cache! "cache-key" do
        json.discussions @discussions do |discussion|
          json.name discussion[:name]
          json.posts discussion[:posts], partial: "post", as: :post
        end
      end
      json.reopen! ["discussions", "posts", "author"] do |author|
        json.middle_name "test"
      end
    JBUILDER
    result = render(code, discussions: discussions)
    assert_equal "test", result["discussions"][0]["posts"][0]["author"]["middle_name"]
    assert_equal [], result["discussions"][1]["posts"]
  end

  private
    def render(*args)
      JSON.load render_without_parsing(*args)
    end

    def render_without_parsing(source, assigns = {})
      view = build_view(fixtures: PARTIALS.merge("source.json.jbuilder" => source), assigns: assigns)
      view.render(template: "source.json.jbuilder")
    end

    def build_view(options = {})
      resolver = ActionView::FixtureResolver.new(options.fetch(:fixtures))
      lookup_context = ActionView::LookupContext.new([ resolver ], {}, [""])
      controller = ActionView::TestCase::TestController.new

      # TODO: Use with_empty_template_cache unconditionally after dropping support for Rails <6.0.
      view = if ActionView::Base.respond_to?(:with_empty_template_cache)
        ActionView::Base.with_empty_template_cache.new(lookup_context, options.fetch(:assigns, {}), controller)
      else
        ActionView::Base.new(lookup_context, options.fetch(:assigns, {}), controller)
      end

      def view.view_cache_dependencies; []; end

      view
    end
end
