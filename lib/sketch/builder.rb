require_relative 'dsl'
require_relative 'group'
require_relative 'builder/polyline'

class Sketch
    class Builder
	attr_reader :sketch

	include Sketch::DSL

	# @group Convenience constants
	Point = Geometry::Point
	Rectangle = Geometry::Rectangle
	Size = Geometry::Size
	# @endgroup

	def initialize(sketch=nil, &block)
	    @sketch = sketch || Sketch.new
	    evaluate(&block) if block_given?
	end

	# Evaluate a block and return a new {Path}
	#  Use the trick found here http://www.dan-manges.com/blog/ruby-dsls-instance-eval-with-delegation
	#  to allow the DSL block to call methods in the enclosing *lexical* scope
	# @return [Sketch]	A new {Sketch} initialized with the given block
	def evaluate(&block)
	    if block_given?
		@self_before_instance_eval = eval "self", block.binding
		self.instance_eval &block
	    end
	    @sketch
	end

	# The second half of the instance_eval delegation trick mentioned at
	#   http://www.dan-manges.com/blog/ruby-dsls-instance-eval-with-delegation
	def method_missing(method, *args, &block)
	    add_symbol = ('add_' + method.to_s).to_sym
	    if @sketch.respond_to? add_symbol
		@sketch.send(add_symbol, *args, &block)
	    elsif @sketch.respond_to? method
		@sketch.send method, *args, &block
	    elsif @self_before_instance_eval.respond_to? method
		@self_before_instance_eval.send method, *args, &block
	    else
		super if defined?(super)
	    end
	end

# @group Accessors

	# !@attribute [r] elements
	#   @return [Array] The current list of elements
	def elements
	    @sketch.elements
	end

# @endgroup

	# Define a named parameter
	# @param [Symbol] name	The name of the parameter
	# @param [Proc] block	A block that evaluates to the value of the parameter
	def let name, &block
	    @sketch.define_parameter name, &block
	end

	# @group Command handlers

	# Create a {Group} with an optional name and transformation
	def group(*args, &block)
	    @sketch.push Sketch::Builder.new(Group.new(*args)).evaluate(&block)
	end

	# Use the given block to build a {Polyline} and then append it to the {Sketch}
	def polyline(&block)
	    push Builder::Polyline.new.evaluate(&block)
	end

	# Append a new object (with optional transformation) to the {Sketch}
	# @return [Sketch]  the {Sketch} that was appended to
	def push(*args)
	    @sketch.push *args
	end

	# Create a {Rectangle} from the given arguments and append it to the {Sketch}
	def rectangle(*args)
	    @sketch.push Rectangle.new(*args)
	    last
	end

	# Create a {Group} using the given translation
	# @param [Point] point	The distance by which to translate the enclosed geometry
	def translate(*args, &block)
	    point = Point[*args]
	    raise ArgumentError, 'Translation is limited to 2 dimensions' if point.size > 2
	    group(origin:point, &block)
	end

	# @endgroup
    end
end
