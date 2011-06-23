# Implements the core functionality of modules. This is inherited from
# by instances of {Class}, so these methods are also available to
# classes.
class Module

  def name
    `return self.__classid__;`
  end

  def ===(obj)
    obj.kind_of? self
  end

  def define_method(method_id, &block)
    raise LocalJumpError, "no block given" unless block_given?
    `$rb.define_method(self, #{method_id.to_s}, block)`
    nil
  end

  def attr_accessor(*attrs)
    attr_reader *attrs
    attr_writer *attrs
  end

  def attr_reader(*attrs)
    attrs.each do |a|
      method_id = a.to_s
      `$rb.define_method(self, method_id, function(self) {
        var iv = self['@' + method_id];
        return iv == undefined ? nil : iv;
      });`
    end
    nil
  end

  def attr_writer(*attrs)
    attrs.each do |a|
      method_id = a.to_s
      `$rb.define_method(self, method_id + '=', function(self, val) {
        return self['@' + method_id] = val;
      });`
    end
    nil
  end

  def alias_method(new_name, old_name)
    `$rb.alias_method(self, #{new_name.to_s}, #{old_name.to_s});`
    self
  end

  def to_s
    `return self.__classid__;`
  end

  def const_set(id, value)
    `return $rb.cs(self, #{id.to_s}, value);`
  end

  def class_eval(str = nil, &block)
    if block_given?
      `block(self)`
    else
      raise "need to compile str"
    end
  end

  def module_eval(str = nil, &block)
    class_eval str, &block
  end

  def extend(mod)
    `$rb.extend_module(self, mod)`
    nil
  end
end

