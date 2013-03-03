def safe(level)
  proc{
    $SAFE = level
    yield
  }.call
end

class Streams
  def initialize(cls, num, seed)
    @cls = cls
    @num = num
    @seed = seed
  end

  TABLE = [nil,0,1,3,5,7,3,10,15,20,25,30,20,40,50,60,70,50,100,150,300]

  def gen_cards(seed)
    srand(seed)
    ((1..10).to_a + (11..19).to_a * 2 + (20..30).to_a + [0]).sort_by{rand}
  end
  
  def eval_once(seed_offset)
    solver = safe(4){@cls.new()}
    map = Array.new(20)
    cards = gen_cards(@seed + seed_offset)

    20.times do
      c = cards.pop
      pos = safe(4){solver.on_card(c)}
      raise "Invalid position" unless (0..19).cover?(pos)
      raise "Position already in use" if map[pos]
      map[pos] = c
    end
    
    score(map)
  end

  def score(map)
    wild_index = map.find_index(0)
    pats = [map.dup, map.dup]
    if wild_index
      (pats << map.dup).last[wild_index] = map[wild_index-1] if wild_index > 0
      (pats << map.dup).last[wild_index] = map[wild_index+1] if wild_index <19
    else
      pats << map.dup
    end
    pats.map{|x| score_without_wild(x)}.max
  end

  def score_without_wild(map)
    current = 0
    seqs = [[map[0]]]
    1.upto(19) do |i|
      if seqs.last.last <= map[i]
        seqs.last << map[i]
      else
        seqs << [map[i]]
      end
    end
    seqs.map{|x| TABLE[x.size]}.inject(:+)
  end

  def eval
    sum = (0...@num).to_a.map.with_index{ |x, i|
      eval_once(i)
    }.inject(:+)
    puts sum / @num.to_f
  end
end

safe(3) do
  TaintMod = Module.new
end

src = File.read(ARGV[0])
safe(4) do
  TaintMod.module_eval(src)
end

Streams.new(TaintMod::Solver, ARGV[1].to_i, (ARGV[2] || 0).to_i).eval
