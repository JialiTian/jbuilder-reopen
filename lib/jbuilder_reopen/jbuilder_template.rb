class JbuilderTemplate
  def reopen!(keys=[], &block)
    keys = keys.dup
    if keys.empty?
      _scope(@attributes) { yield @attributes }
    else
      return if _blank?
      key = keys.shift
      result = if ::Array === @attributes[key]
        @attributes[key].map do |element|
          _scope(element) { reopen!(keys, &block) }
        end
      elsif ::Hash === @attributes[key]
        _scope(@attributes[key]) { reopen!(keys, &block) }
      end
      @attributes[key] = result if result.present?
      @attributes
    end
  end
end
