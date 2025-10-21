# frozen_string_literal: true

require 'thread'
require 'delegate'
require 'set'

Enumerable.class_eval do
  # Run enumerable method blocks in threads
  #
  #   urls.in_threads.map do |url|
  #     url.fetch
  #   end
  #
  # Specify number of threads to use:
  #
  #   files.in_threads(4).all? do |file|
  #     file.valid?
  #   end
  #
  # Passing block runs it against `each`
  #
  #   urls.in_threads.each{ ... }
  #
  # is same as
  #
  #   urls.in_threads{ ... }
  def in_threads(thread_count = 10, &block)
    InThreads.new(self, thread_count, &block)
  end
end

# Run Enumerable methods with blocks in threads
class InThreads < SimpleDelegator
  protected :__getobj__, :__setobj__

  attr_reader :enumerable, :thread_count

  def self.new(enumerable, thread_count = 10, &block)
    if block
      super.each(&block)
    else
      super
    end
  end

  def initialize(enumerable, thread_count = 10)
    super(enumerable)

    @enumerable, @thread_count = enumerable, thread_count.to_i

    fail ArgumentError, '`enumerable` should include Enumerable.' unless enumerable.is_a?(Enumerable)

    fail ArgumentError, '`thread_count` can\'t be less than 2.' if thread_count < 2
  end

  # Creates new instance using underlying enumerable and new thread_count
  def in_threads(thread_count = 10, &block)
    self.class.new(enumerable, thread_count, &block)
  end

  class << self
    # Specify runner to use
    #
    #   use :run_in_threads_use_block_result, :for => %w[all? any? none? one?]
    #
    # `:for` is required
    # `:ignore_undefined` ignores methods which are not present in
    # `Enumerable.instance_methods`
    def use(runner, options)
      methods = Array(options[:for])
      fail 'no methods provided using :for option' if methods.empty?

      ignore_undefined = options[:ignore_undefined]
      methods.each do |method|
        next if ignore_undefined && !enumerable_method?(method)

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{method}(*args, &block)             # def foo_bar(*args, &block)
            if block                               #   if block
              #{runner}(:#{method}, *args, &block) #     run_in_threads_method(:foo_bar, *args, &block)
            else                                   #   else
              enumerable.#{method}(*args)          #     enumerable.foo_bar(*args)
            end                                    #   end
          end                                      # end
        RUBY
      end
    end

  private

    def enumerable_method?(name)
      Enumerable.method_defined?(name)
    end
  end

  use :run_in_threads_ignore_block_result, :for => %w[each]
  use :run_in_threads_ignore_block_result, :for => %w[
    reverse_each
    each_with_index enum_with_index
    each_cons each_slice enum_cons enum_slice
    zip
    cycle
    each_entry
    each_with_object
  ], :ignore_undefined => true
  use :run_in_threads_use_block_result, :for => %w[
    all? any? none? one?
    detect find find_index drop_while take_while
    partition find_all select filter reject count
    collect map group_by max_by min_by minmax_by sort_by sum uniq
    flat_map collect_concat
    filter_map
    to_set
  ], :ignore_undefined => true

  DEPENDENT_BLOCK_CALLS = %w[
    inject reduce
    max min minmax sort
  ].map(&:to_sym)

  ENUMERATOR_RETURNED = %w[
    chunk chunk_while slice_before slice_after slice_when
  ].map(&:to_sym)

  BLOCKLESS_METHODS = %w[
    entries to_a
    drop take
    first
    include? member?
    lazy
    chain
    tally
    compact
  ].map(&:to_sym)

  if enumerable_method?(:to_h) && [[0, 0]].to_h{ [1, 1] } == {1 => 1}
    use :run_in_threads_use_block_result, :for => %w[to_h]
  else
    BLOCKLESS_METHODS << :to_h
  end

  INCOMPATIBLE_METHODS = DEPENDENT_BLOCK_CALLS + ENUMERATOR_RETURNED + BLOCKLESS_METHODS

  # Special case method, works by applying `run_in_threads_use_block_result` with
  # map on enumerable returned by blockless run
  def grep(*args, &block)
    if block
      self.class.new(enumerable.grep(*args), thread_count).map(&block)
    else
      enumerable.grep(*args)
    end
  end

  if enumerable_method?(:grep_v)
    # Special case method, works by applying `run_in_threads_use_block_result` with
    # map on enumerable returned by blockless run
    def grep_v(*args, &block)
      if block
        self.class.new(enumerable.grep_v(*args), thread_count).map(&block)
      else
        enumerable.grep_v(*args)
      end
    end
  end

  # befriend with progress gem
  def with_progress(title = nil, length = nil, &block)
    ::Progress::WithProgress.new(self, title, length, &block)
  end

protected

  # Enum out of queue
  class QueueEnum
    include Enumerable

    def initialize(size = nil)
      @queue = size ? SizedQueue.new(size) : Queue.new
    end

    def each(&block)
      while (args = @queue.pop)
        block.call(*args)
      end
      nil # non reusable
    end

    def push(*args)
      @queue.push(args) unless @closed
    end

    def close(clear = false)
      @closed = true
      @queue.clear if clear
      @queue.push(nil)
    end
  end

  # Thread pool
  class Pool
    attr_reader :exception

    def initialize(thread_count)
      @queue = Queue.new
      @mutex = Mutex.new
      @pool = Array.new(thread_count) do
        Thread.new do
          while (block = @queue.pop)
            block.call
            break if stop?
          end
        end
      end
    end

    def run(&block)
      @queue.push(block)
    end

    def stop?
      @stop || @exception
    end

    def stop!
      @stop = true
    end

    def finalize
      @pool.
        each{ @queue.push(nil) }.
        each(&:join)
    end

    def catch
      yield
    rescue Exception => e
      @mutex.synchronize{ @exception ||= e } unless @exception
      nil
    end
  end

  # Use for methods which don't use block result
  def run_in_threads_ignore_block_result(method, *args, &block)
    pool = Pool.new(thread_count)
    wait = SizedQueue.new(thread_count - 1)
    begin
      pool.catch do
        enumerable.send(method, *args) do |*block_args|
          pool.run do
            pool.catch do
              block.call(*block_args)
            end
            wait.pop
          end
          wait.push(nil)
          break if pool.stop?
        end
      end
    ensure
      pool.finalize
      if (e = pool.exception)
        return e.exit_value if e.is_a?(LocalJumpError) && e.reason == :break

        fail e
      end
    end
  end

  # Use for methods which do use block result
  def run_in_threads_use_block_result(method, *args, &block)
    pool = Pool.new(thread_count)
    enum_a = QueueEnum.new
    enum_b = QueueEnum.new(thread_count - 1)
    results = SizedQueue.new(thread_count - 1)
    filler = filler_thread(pool, [enum_a, enum_b])
    runner = runner_thread(pool, enum_a, results, &block)

    begin
      pool.catch do
        enum_b.send(method, *args) do
          result = results.pop.pop
          break if pool.stop?

          result
        end
      end
    ensure
      pool.stop!
      enum_a.close(true)
      enum_b.close(true)
      results.clear
      pool.finalize
      runner.join
      filler.join
      if (e = pool.exception)
        return e.exit_value if e.is_a?(LocalJumpError) && e.reason == :break

        fail e
      end
    end
  end

private

  def filler_thread(pool, enums)
    Thread.new do
      pool.catch do
        enumerable.each do |*block_args|
          enums.each do |enum|
            enum.push(*block_args)
          end
          break if pool.stop?
        end
      end
      enums.each(&:close)
    end
  end

  def runner_thread(pool, enum, results, &block)
    Thread.new do
      enum.each do |*block_args|
        queue = Queue.new
        pool.run do
          queue.push(pool.catch{ block.call(*block_args) })
        end
        results.push(queue)
        break if pool.stop?
      end
    end
  end
end
