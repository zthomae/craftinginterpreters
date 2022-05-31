require "set"

module OutputPatterns
  EXPECTED_OUTPUT = /\/\/ expect: ?(.*)/
  EXPECTED_ERROR = /\/\/ (Error.*)/
  ERROR_LINE = /\/\/ \[((java|c) )?line (\d+)\] (Error.*)/
  EXPECTED_RUNTIME_ERROR = /\/\/ expect runtime error: (.+)/
  SYNTAX_ERROR = /\[.*line (\d+)\] (Error.+)/
  STACK_TRACE = /\[line (\d+)\]/
  NONTEST = /\/\/ nontest/
end

# TODO: No globals
$passed = 0
$failed = 0
$skipped = 0
$expectations = 0
$all_suites = {}
$c_suites = []
$java_suites = []

Suite = Struct.new(:name, :language, :executable, :args, :tests)

def main
  define_test_suites

  puts $all_suites
end

ExpectedOutput = Struct.new(:line, :output)

class Test
  def initialize(path)
    @path = path
    @expected_output = []
    @expected_errors = Set.new
    @failures = []

    # Do I need these in the constructor?
    @runtime_error_line = 0
    @expected_exit_code = 0
  end

  private

  attr_reader :path
end

def define_test_suites
  c = ->(name, tests) do
    executable = name == "clox" ? "build/cloxd" : "build/#{name}"
    $all_suites[name] = Suite.new(name, "c", executable, [], tests)
    $c_suites.append(name)
  end

  java = ->(name, tests) do
    dir = name == "jlox" ? "build/java" : "build/gen/#{name}"
    $all_suites[name] = Suite.new(name, "java", "java", ["-cp", dir, "com.craftinginterpreters.lox.Lox"], tests)
    $java_suites.append(name)
  end

  early_chapters = {
    "test/scanning" => "skip",
    "test/expressions" => "skip",
  }

  java_NaN_equality = {
    "test/number/nan_equality.lox" => "skip",
  }

  no_java_limits = {
    "test/limit/loop_too_large.lox" => "skip",
    "test/limit/no_reuse_constants.lox" => "skip",
    "test/limit/too_many_constants.lox" => "skip",
    "test/limit/too_many_locals.lox" => "skip",
    "test/limit/too_many_upvalues.lox" => "skip",

    # Rely on JVM for stack overflow checking.
    "test/limit/stack_overflow.lox" => "skip",
  }

  no_java_classes = {
    "test/assignment/to_this.lox" => "skip",
    "test/call/object.lox" => "skip",
    "test/class" => "skip",
    "test/closure/close_over_method_parameter.lox" => "skip",
    "test/constructor" => "skip",
    "test/field" => "skip",
    "test/inheritance" => "skip",
    "test/method" => "skip",
    "test/number/decimal_point_at_eof.lox" => "skip",
    "test/number/trailing_dot.lox" => "skip",
    "test/operator/equals_class.lox" => "skip",
    "test/operator/equals_method.lox" => "skip",
    "test/operator/not_class.lox" => "skip",
    "test/regression/394.lox" => "skip",
    "test/super" => "skip",
    "test/this" => "skip",
    "test/return/in_method.lox" => "skip",
    "test/variable/local_from_method.lox" => "skip",
  }

  no_java_functions = {
    "test/call" => "skip",
    "test/closure" => "skip",
    "test/for/closure_in_body.lox" => "skip",
    "test/for/return_closure.lox" => "skip",
    "test/for/return_inside.lox" => "skip",
    "test/for/syntax.lox" => "skip",
    "test/function" => "skip",
    "test/operator/not.lox" => "skip",
    "test/regression/40.lox" => "skip",
    "test/return" => "skip",
    "test/unexpected_character.lox" => "skip",
    "test/while/closure_in_body.lox" => "skip",
    "test/while/return_closure.lox" => "skip",
    "test/while/return_inside.lox" => "skip",
  }

  no_java_resolution = {
    "test/closure/assign_to_shadowed_later.lox" => "skip",
    "test/function/local_mutual_recursion.lox" => "skip",
    "test/variable/collide_with_parameter.lox" => "skip",
    "test/variable/duplicate_local.lox" => "skip",
    "test/variable/duplicate_parameter.lox" => "skip",
    "test/variable/early_bound.lox" => "skip",

    # Broken because we haven"t fixed it yet by detecting the error.
    "test/return/at_top_level.lox" => "skip",
    "test/variable/use_local_in_initializer.lox" => "skip",
  }

  no_c_control_flow = {
    "test/block/empty.lox" => "skip",
    "test/for" => "skip",
    "test/if" => "skip",
    "test/limit/loop_too_large.lox" => "skip",
    "test/logical_operator" => "skip",
    "test/variable/unreached_undefined.lox" => "skip",
    "test/while" => "skip",
  }

  no_c_functions = {
    "test/call" => "skip",
    "test/closure" => "skip",
    "test/for/closure_in_body.lox" => "skip",
    "test/for/return_closure.lox" => "skip",
    "test/for/return_inside.lox" => "skip",
    "test/for/syntax.lox" => "skip",
    "test/function" => "skip",
    "test/limit/no_reuse_constants.lox" => "skip",
    "test/limit/stack_overflow.lox" => "skip",
    "test/limit/too_many_constants.lox" => "skip",
    "test/limit/too_many_locals.lox" => "skip",
    "test/limit/too_many_upvalues.lox" => "skip",
    "test/regression/40.lox" => "skip",
    "test/return" => "skip",
    "test/unexpected_character.lox" => "skip",
    "test/variable/collide_with_parameter.lox" => "skip",
    "test/variable/duplicate_parameter.lox" => "skip",
    "test/variable/early_bound.lox" => "skip",
    "test/while/closure_in_body.lox" => "skip",
    "test/while/return_closure.lox" => "skip",
    "test/while/return_inside.lox" => "skip",
  }

  no_c_classes = {
    "test/assignment/to_this.lox" => "skip",
    "test/call/object.lox" => "skip",
    "test/class" => "skip",
    "test/closure/close_over_method_parameter.lox" => "skip",
    "test/constructor" => "skip",
    "test/field" => "skip",
    "test/inheritance" => "skip",
    "test/method" => "skip",
    "test/number/decimal_point_at_eof.lox" => "skip",
    "test/number/trailing_dot.lox" => "skip",
    "test/operator/equals_class.lox" => "skip",
    "test/operator/equals_method.lox" => "skip",
    "test/operator/not.lox" => "skip",
    "test/operator/not_class.lox" => "skip",
    "test/regression/394.lox" => "skip",
    "test/return/in_method.lox" => "skip",
    "test/super" => "skip",
    "test/this" => "skip",
    "test/variable/local_from_method.lox" => "skip",
  }

  no_c_inheritance = {
    "test/class/local_inherit_other.lox" => "skip",
    "test/class/local_inherit_self.lox" => "skip",
    "test/class/inherit_self.lox" => "skip",
    "test/class/inherited_method.lox" => "skip",
    "test/inheritance" => "skip",
    "test/regression/394.lox" => "skip",
    "test/super" => "skip",
  }

  java.call("jlox", { "test" => "pass" }.merge(early_chapters, java_NaN_equality, no_java_limits))
  java.call("chap04_scanning", { "test" => "skip", "test/scanning" => "pass" })
  java.call("chap06_parsing", { "test" => "skip", "test/expressions/parse.lox" => "pass" })
  java.call("chap07_evaluating", { "test" => "skip", "test/expressions/evaluate.lox" => "pass" })
  java.call("chap08_statements", { "test" => "pass" }.merge(
    early_chapters,
    java_NaN_equality,
    no_java_limits,
    no_java_functions,
    no_java_resolution,
    no_java_classes,
    {
      # No control flow.
      "test/block/empty.lox" => "skip",
      "test/for" => "skip",
      "test/if" => "skip",
      "test/logical_operator" => "skip",
      "test/while" => "skip",
      "test/variable/unreached_undefined.lox" => "skip",
    }
  ))
  java.call("chap09_control", { "test" => "pass" }.merge(early_chapters, java_NaN_equality, no_java_limits, no_java_functions, no_java_resolution, no_java_classes))
  java.call("chap10_functions", { "test" => "pass" }.merge(early_chapters, java_NaN_equality, no_java_limits, no_java_resolution, no_java_classes))
  java.call("chap11_resolving", { "test" => "pass" }.merge(early_chapters, java_NaN_equality, no_java_limits, no_java_classes))
  java.call("chap12_classes", { "test" => "pass" }.merge(early_chapters, no_java_limits, java_NaN_equality, {
    # No inheritance.
    "test/class/local_inherit_other.lox" => "skip",
    "test/class/local_inherit_self.lox" => "skip",
    "test/class/inherit_self.lox" => "skip",
    "test/class/inherited_method.lox" => "skip",
    "test/inheritance" => "skip",
    "test/regression/394.lox" => "skip",
    "test/super" => "skip",
  }))
  java.call("chap13_inheritance", { "test" => "pass" }.merge(early_chapters, java_NaN_equality, no_java_limits))

  c.call("clox", { "test" => "pass" }.merge(early_chapters))
  c.call("chap17_compiling", { "test" => "skip",  "test/expressions/evaluate.lox" => "pass" })
  c.call("chap18_types", { "test" => "skip", "test/expressions/evaluate.lox" => "pass" })
  c.call("chap19_strings", { "test" => "skip", "test/expressions/evaluate.lox" => "pass" })
  c.call("chap20_hash", { "test" => "skip", "test/expressions/evaluate.lox" => "pass" })
  c.call("chap21_global", { "test" => "pass" }.merge(
    early_chapters,
    no_c_control_flow,
    no_c_functions,
    no_c_classes,

    # No blocks.
    "test/assignment/local.lox" => "skip",
    "test/variable/in_middle_of_block.lox" => "skip",
    "test/variable/in_nested_block.lox" => "skip",
    "test/variable/scope_reuse_in_different_blocks.lox" => "skip",
    "test/variable/shadow_and_local.lox" => "skip",
    "test/variable/undefined_local.lox" => "skip",

    # No local variables.
    "test/block/scope.lox" => "skip",
    "test/variable/duplicate_local.lox" => "skip",
    "test/variable/shadow_global.lox" => "skip",
    "test/variable/shadow_local.lox" => "skip",
    "test/variable/use_local_in_initializer.lox" => "skip",
  ))
  c.call("chap22_local", { "test" => "pass" }.merge(early_chapters, no_c_control_flow, no_c_functions, no_c_classes))
  c.call("chap23_jumping", { "test" => "pass" }.merge(early_chapters, no_c_functions, no_c_classes))
  c.call("chap24_calls", { "test" => "pass" }.merge(early_chapters, no_c_classes, {
    # No closures.
    "test/closure" => "skip",
    "test/for/closure_in_body.lox" => "skip",
    "test/for/return_closure.lox" => "skip",
    "test/function/local_recursion.lox" => "skip",
    "test/limit/too_many_upvalues.lox" => "skip",
    "test/regression/40.lox" => "skip",
    "test/while/closure_in_body.lox" => "skip",
    "test/while/return_closure.lox" => "skip",
  }))
  c.call("chap25_closures", { "test" => "pass" }.merge(early_chapters, no_c_classes))
  c.call("chap26_garbage", { "test" => "pass" }.merge(early_chapters, no_c_classes))
  c.call("chap27_classes", { "test" => "pass" }.merge(early_chapters, no_c_inheritance, {
    # No methods.
    "test/assignment/to_this.lox" => "skip",
    "test/class/local_reference_self.lox" => "skip",
    "test/class/reference_self.lox" => "skip",
    "test/closure/close_over_method_parameter.lox" => "skip",
    "test/constructor" => "skip",
    "test/field/get_and_set_method.lox" => "skip",
    "test/field/method.lox" => "skip",
    "test/field/method_binds_this.lox" => "skip",
    "test/method" => "skip",
    "test/operator/equals_class.lox" => "skip",
    "test/operator/equals_method.lox" => "skip",
    "test/return/in_method.lox" => "skip",
    "test/this" => "skip",
    "test/variable/local_from_method.lox" => "skip",
  }))
  c.call("chap28_methods", { "test" => "pass" }.merge(early_chapters, no_c_inheritance))
  c.call("chap29_superclasses", { "test" => "pass" }.merge(early_chapters))
  c.call("chap30_optimization", { "test" => "pass" }.merge(early_chapters))
end

main
