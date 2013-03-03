# pooltest.rb


require "./process_pool"


class MyWorker < ProcessPool::Worker
    def work(item)
        puts "start #{item}"
        sleep 1
        puts "end #{item}"
        [item, [item]]
    end
end

pp = ProcessPool.new(3, :worker_class => MyWorker)

while true
    5.times do |i|
        pp.enqueue i
    end

    pp.start
    pp.wait
    sleep 1

    puts "result"
    while res = pp.pop_result
        p res
    end
end
