# coding: utf-8
# my_solver.rb

require "./solver_lib"
# STDOUT.sync = true

class Solver
    def initialize(data_filename)
        # スペースの評価値を読み込み
        # [space_size, num_valid, num_total]
        @prob = Marshal.load(File.read(data_filename))
    end

    def log(msg)
        #puts msg
    end

    def init
        @map = Array.new(20)
        @pos = (0..19).inject({}){|t,i| t[i]=true;t}
        srand(10)
        @numbers = ((1..10).to_a + (11..19).to_a * 2 + (20..30).to_a + [0]).sort_by{rand}
    end

    # numを書き込む場所を返してください。
    # numには0から30の数値が入り、0はワイルドカードです。
    # 書き込む場所は0から19の数値です。
    def on_card(num)
        log "===================== on_card(#{num}) ====================="
        ret_index = -1
        max_score = 0
        @numbers.delete_at(@numbers.find_index(num))
        @pos.keys.each do |index|
            fmap = @map.dup
            fmap[index] = num
            score = calc_score(fmap, @numbers.dup)
            if max_score < score
                max_score = score
                ret_index = index
            end
        end
        @map[ret_index] = num
        log "FIX POS[#{ret_index}] = #{num}: #{@map.join('|')}"
        @pos.delete(ret_index)
        ret_index
    end

    def calc_score(map, numbers)
        # [(left_value_idx, left-value right_value_idx right-value count),...]
        spaces = fetch_spaces(map) 
        # log spaces.inspect

        sc = fill_spaces(map, spaces, numbers, 1)
        log "CALC_SCORE: #{sc} -> #{map.join('|')}"
        sc
    end

    def fill_spaces(map, spaces, numbers, prob, depth=1)
        spaces = spaces.dup
        thid = (rand * 1000000).to_i
        log "(#{thid})fill_spaces: #{map.join('|')} #{spaces.inspect} numbers=#{numbers.size}#{numbers.inspect}"
        if spaces.size == 0 || depth > 5
            if depth > 5 # 打ち切り
                log "Cut Search beacause over depth"
                0.upto(19) do |idx|
                    map[idx] = numbers.shift unless map[idx]
                end
            end
            sc = score(map)
            log "Score: #{sc*prob}, #{sc}, #{prob}"
            return sc * prob
        end
        sc = 0
        lidx, lv, ridx, rv, cnt = this_space = spaces.pop
        p3 = p2 = p1 = 0
        # lv <= .. <= rv に収まる確率？ p3: 左右とつながる場合を評価する
        if lv && rv
            nums = select_nums(lv, rv, numbers)
            p3 = get_prob(cnt, nums.size, numbers.size)
            if p3 > 0
                log "(#{thid})=== P3(#{lv},#{rv},#{p3}) ====  #{map.join('|')} #{nums}"
                sc += fill_recursive(map, spaces, numbers, prob, p3, nums, this_space, true, true, depth)
            end
        end
         #       .. <= rv に収まる確率？ p2: 右側とつながる場合を評価する
        if rv # 右側に数字が存在している
            nums = select_nums(nil, rv, numbers)
            p2 = [get_prob(cnt, nums.size, numbers.size) - p3, 0].max
            if p2 > 0
                log "(#{thid})=== P2(#{lv},#{rv},#{p2}) ==== #{map.join('|')} #{nums}"
                sc += fill_recursive(map, spaces, numbers, prob, p2, nums, this_space, false, true, depth)
            end
        end
        # lv <= ..       に収まる確率？ p1: 左側とつながる場合を評価する
        if lv
            nums = select_nums(lv, nil, numbers)
            p1 = [get_prob(cnt, nums.size, numbers.size) - p3, 0].max
            if p1 > 0
                log "(#{thid})=== P1(#{lv},#{rv},#{p1}) ====  #{map.join('|')} #{nums}"
                sc += fill_recursive(map, spaces, numbers, prob, p1, nums, this_space, true, false, depth)
            end
        end
        # 収まらない確率              ? p0
        nums = select_nums(nil, nil, numbers)
        p0 = [get_prob(cnt, nums.size, numbers.size) - p1 - p2 - p3, 0].max # ? よくわかんな。。
        if p0 > 0
            log "(#{thid})=== P0(#{lv},#{rv},#{p0}) ====  #{map.join('|')} nums=#{nums.size}#{nums.inspect} numbers=#{numbers.size}#{numbers.inspect}"
            sc += fill_recursive(map, spaces, numbers, prob, p0, nums, this_space, false, false, depth)
        end
        sc
    end

    def fill_recursive(map, spaces, numbers, prob, this_prob, nums, this_space, conn_left, conn_right, depth)
        lidx, lv, ridx, rv, cnt = this_space
        use_nums = nums[0...cnt].sort
        fmap = map.dup
        fnumbers = numbers.dup
        lidx = (lidx||-1)+1
        ridx = (ridx||20)-1
        if not conn_left and lv
            invaid_nums = select_nums(nil, lv-1, (fnumbers - use_nums)).delete_if{|x| x == 0}
            return 0 if invaid_nums.size == 0
            x = fmap[lidx] = invaid_nums.shuffle[0]
            fnumbers.delete_at(fnumbers.find_index(x))
            lidx += 1
        end
        if not conn_right and rv
            invaid_nums = select_nums(rv+1, nil, (fnumbers - use_nums)).delete_if{|x| x == 0}
            return 0 if invaid_nums.size == 0
            if not fmap[ridx] # 既にlidxによって埋まっている場合がある
                x = fmap[ridx] = invaid_nums.shuffle[0]
                fnumbers.delete_at(fnumbers.find_index(x))
                ridx -= 1
            end
        end
        (lidx).upto(ridx) {|idx| 
            fmap[idx] = x = use_nums.shift
            fnumbers.delete_at(fnumbers.find_index(x)) # 数字は重複があるのでdeleteは使えない..
        }
        fill_spaces(fmap, spaces, fnumbers, prob*this_prob, depth+1)
    end

    def get_prob(space_size, num_valid, num_total)
        log "========================= call prob #{[space_size, num_valid, num_total]} ==========="
        return 0 if num_valid < space_size
        pp = @prob[[space_size, num_valid, num_total]]
        if pp <= 0
            log "========================= PROB<=0 #{[space_size, num_valid, num_total]} ==========="
        end
        pp
    end

    def select_nums(lv, rv, numbers)
        numbers.select{|x| ((lv||-1) <= x && x <= (rv||1000)) || x == 0}
    end

    def fetch_spaces(map)
        # [(left_value_idx, left-value right_value_idx right-value count),...]
        spaces = []
        left_value = nil
        left_idx = nil
        cnt = 0
        (0..19).each do |idx|
            if map[idx] and cnt > 0 # 空白の次に何か数字があった
                spaces << [left_idx, left_value, idx, map[idx], cnt]
                cnt = 0
            end
            if map[idx]
                left_value = map[idx] 
                left_idx = idx
            else
                cnt += 1
            end
        end
        spaces << [left_idx, left_value, nil, nil, cnt] if cnt > 0
        spaces
    end

end

class Streams
  def initialize(data_filename, num, seed)
    @solver = Solver.new(data_filename)
    @num = num
    @seed = seed
  end

  def eval_once(seed_offset)
    @solver.init
    map = Array.new(20)
    cards = gen_cards(@seed + seed_offset)

    20.times do
      c = cards.pop
      pos = @solver.on_card(c)
      raise "Invalid position" unless (0..19).cover?(pos)
      raise "Position already in use" if map[pos]
      map[pos] = c
      puts "Streams" + map.map{|x| sprintf("%02s", x)}.join("|") if $DEBUG
    end
    
    s = score(map)
    # puts "score: #{s}"
    s
  end

  def eval
    sum = (0...@num).to_a.map.with_index{ |x, i|
      eval_once(i)
    }.inject(:+)
    sum / @num.to_f
  end
end

class Trainer
    require "securerandom"
    def initialize(data_dir, num_eval, seed)
        @data_dir = data_dir
        @num_eval = num_eval
        @seed = seed
        @num_next = 10 # 次世代に残れる数
        @num_child_per_parents = 3 # １つの親が作る子供の数
        @mutation_rate = 0.01
        @mutation_val = 1.0
        @kousa_rate = 0.01
        @log_file = "train.log"
    end

    def log(msg)
        fmt = "#{Time.now.to_s}: #{msg}"
        File::open(@log_file, "a") do |f|
            f.write("#{fmt}\n")
        end
        puts fmt
    end

    def train
        seed_offset = i = 0
        @result_cache = {}
        while true
            log "=== start training loop #{i}"
            train_loop(@seed + seed_offset)
            i += 1
            if i % 10 == 0
                seed_offset += 50
                @result_cache = {}
            end
        end
    end

    def train_loop(seed)
        # find children
        children = Dir.glob("#{@data_dir}/*.data")
        # generate children
        new_children = generate_new_children(children)
        # evaluate each child
        child_score = {}
        log "== #{new_children.size} children will be tested"
        new_children.each_with_index do |child, n|
            cache_key = ["#{@data_dir}/#{child}", @num_eval, seed]
            if @result_cache[cache_key] == nil
                ave_score = Streams.new("#{@data_dir}/#{child}", @num_eval, seed).eval
                @result_cache[cache_key] = ave_score
            end
            child_score[child] = @result_cache[cache_key]
            log "No.#{n}: #{child} Score: #{child_score[child]}"
        end
        # kill bad children
        survives = child_score.sort_by{|k,v| -v}[0...@num_next].map{|x| x[0]}
        log "================ BEST #{@num_next} ===================="
        survives.each do |child|
            log "#{child} Score: #{child_score[child]}"
        end
        (new_children - survives).each do |child|
            File.delete "#{@data_dir}/#{child}"
        end
    end

    def generate_new_children(children)
        log "genearate new children"
        raise "No child found" if children.size == 0
        @num_gen_limit = (@num_child_per_parents+1) * @num_next
        @num_gen_children = children.size
        mutant(@num_child_per_parents/2, children)
        ((@num_gen_limit - @num_gen_children)/2).times do |i|
            kousa(children)
        end
        Dir.glob("#{@data_dir}/*.data").map{|x| File.basename x}
    end

    def mutant(num_per_parent, children)
        srand()
        children.each do |child|
            params = Marshal.load(File.read(child))
            num_per_parent.times do 
                break if @num_gen_children >= @num_gen_limit
                @num_gen_children += 1
                params.keys.shuffle[0...(params.size*@mutation_rate).to_i].each do |k|
                    params[k] = [[params[k] + (rand-0.5)*@mutation_val, 0].max, 1].min
                end
                File.write("#{@data_dir}/#{name_child_of(child)}", Marshal.dump(params))
            end
        end
    end

    def kousa(children)
        return if children.size < 2
        ca, cb = children.shuffle[0..1]
        log "kousa #{ca} <-> #{cb}"
        pa = Marshal.load(File.read(ca))
        pb = Marshal.load(File.read(cb))
        pa.keys.shuffle[0...(pa.size*@kousa_rate).to_i].each do |k|
            tmp = pa[k]
            pa[k] = pb[k]
            pb[k] = tmp
        end
        File.write("#{@data_dir}/#{name_child_of(ca)}", Marshal.dump(pa))
        File.write("#{@data_dir}/#{name_child_of(cb)}", Marshal.dump(pb))
    end

    def get_generation(child)
        name = File.basename(child)
        name.split("-")[0].to_i
    end

    def name_child_of(child)
        gen = get_generation(child) + 1
        "#{gen}-#{SecureRandom.uuid}.data"
    end
end

first_arg = ARGV[0]
if first_arg.to_i == 0
    $DEBUG = true
    puts Streams.new(first_arg, ARGV[1].to_i, (ARGV[2] || 0).to_i).eval
else
    $DEBUG = false
    Trainer.new("data", first_arg.to_i, (ARGV[1] || 0).to_i).train
end
