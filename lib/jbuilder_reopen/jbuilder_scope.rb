module JbuilderScope
  def _scope(_attributes=Jbuilder::Blank.new)
    parent_attributes, parent_formatter = @attributes, @key_formatter
    @attributes = _attributes
    yield
    @attributes
  ensure
    @attributes, @key_formatter = parent_attributes, parent_formatter
  end
end

Jbuilder.prepend(JbuilderScope)
