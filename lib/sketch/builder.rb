class Sketch
    class Builder
	attr_reader :sketch

	def initialize(sketch=nil, &block)
	    @sketch = sketch || Sketch.new
	    evaluate(&block) if block_given?
	end

	def evaluate(&block)
	    instance_eval &block
	    @model
	end

	# Define a named parameter
	# @param [Symbol] name	The name of the parameter
	# @param [Proc] block	A block that evaluates to the value of the parameter
	def let name, &block
	    @sketch.define_parameter name, &block
	end

	def push(*args)
	    @sketch.push *args
	end

	def method_missing(id, *args, &block)
	    add_symbol = ('add_' + id.to_s).to_sym
	    if @sketch.respond_to? add_symbol
		@sketch.send(add_symbol, *args, &block)
	    elsif @sketch.respond_to? id
		@sketch.send id, *args, &block
	    else
		super if defined?(super)
	    end
	end
    end
end