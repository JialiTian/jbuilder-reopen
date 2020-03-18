# JbuilderReopen

## Installation

    gem 'jbuilder_reopen'

## Usage

To opmtimise cache, now you can reopen blocks and add additional fields

Examples:

	json.cache! "cache-key" do
    json.posts @posts, partial: "post", as: :post
  end
  json.reopen! ["posts"] do |post|
    json.title post["body"]
    json.reopen! ["author"] do |author|
      json.middle_name author["first_name"]
    end
  end

## Testing
    bundle install
    appraisal install
    appraisal rake test

## Credit
Thank you! https://github.com/rails/jbuilder
