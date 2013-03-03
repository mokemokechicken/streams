require 'msgpack'
require 'thread'

class ProcessPool
  def initialize(num_process, args={})
    queue_size, worker_class = parse_args([
      :queue_size, nil,
      :worker_class, Worker,
    ], args)

    @children = fork_children(num_process, worker_class)
    @threads = []
    @index = 0
    if queue_size.nil?
      @queue = Queue.new
    else
      @queue = SizedQueue.new(queue_size)
    end
    @result_queue = Queue.new
  end

  def start
    consume
  end

  def wait
    loop do
      break if @queue.empty?
      Thread.pass
    end
    @threads.each {|t| t.kill}
  end

  def stop
    @children.each {|c| c.close_pipe; c.wait}
    @threads.each {|t| t.kill}
  end

  def enqueue(item)
    @queue.push item
  end

  def pop_result
    @result_queue.pop
  end

  private
  def fork_children(num, worker_class)
    children = []
    num.times do |i|
      children << fork_child(worker_class, children)
    end
    handle_signal
    children
  end

  def fork_child(worker_class, started_process)
      child_read, parent_write = IO.pipe
      parent_read, child_write = IO.pipe

      pid = Process.fork do
        begin
          worker = worker_class.new

          started_process.each{|p| p.close_pipe}

          parent_write.close
          parent_read.close

          pac = MessagePack::Unpacker.new(child_read)
          begin
            pac.each do |item|
              result = worker.work item
              child_write.write result.to_msgpack
            end
          rescue EOFError
          end
        ensure
          child_read.close
          child_write.close
        end
      end

      child_read.close
      child_write.close

      ChildProcess.new(pid, parent_read, parent_write)
  end

  def handle_signal
    Signal.trap :SIGINT do
      @children.each {|c| w.kill}
      exit 1
    end
  end

  def consume
    @children.length.times do |i|
      @threads << Thread.new do
        child = @children[i]
        pac = MessagePack::Unpacker.new(child.rpipe)

        while item = @queue.pop
          child.wpipe.write item.to_msgpack
          pac.each {|result| @result_queue.push result; break}
        end
      end
    end
  end

  def parse_args(d, a)
    return d.each_slice(2).map {|k,v| a[k] or v}
  end
end

class ProcessPool::Worker
  def initialize
  end

  def work(item)
  end
end

class ProcessPool::ChildProcess
  attr_reader :rpipe, :wpipe

  def initialize(pid, rpipe, wpipe)
    @pid = pid
    @rpipe = rpipe
    @wpipe = wpipe
  end

  def wait
    Process.wait @pid
  end

  def kill
    Process.kill :KILL, @pid
  end

  def close_pipe
    @rpipe.close
    @wpipe.close
  end
end