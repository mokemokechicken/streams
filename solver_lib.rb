# coding: utf-8
# my_solver.rb

#         -  1 2 3 4 5 6  7  8  9 10 11 12 13 14 15 16 17  18  19  20
TABLE = [nil,0,1,3,5,7,3,10,15,20,25,30,20,40,50,60,70,50,100,150,300]

def gen_cards(seed)
    srand(seed)
    ((1..10).to_a + (11..19).to_a * 2 + (20..30).to_a + [0]).sort_by{rand}
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
