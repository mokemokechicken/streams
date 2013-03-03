# coding: utf-8

def main()
    # g(space_size, num_valid, num_total) -> probability
    # space_size: 1..19
    # num_total: 21..39
    # num_valid: 1..39. 0の時は 0固定とする。 
    hash = Hash.new(0)
    (1..19).each do |space_size|
        ((space_size+20)..39).each do |num_total|
            trash_size = num_total - 20 - space_size
            total_try = space_size+trash_size
            # valid, invalid の ボールがあって、 space_size+trash_size 回の試行で、space_size回以上validを取り出す確率
            # 白４黒４のぼーる。３回の試行で２個以上白のボールを取り出す確率
            # 4C2 * 4C1 / 8C3 + 4C3 * 4C0 / 8C3
            (space_size..num_total).each do |num_valid|
                num_invalid = num_total - num_valid
                x = 0
                space_size.upto(total_try) do |s|
                    pp = combi(num_valid, s)*combi(num_invalid, total_try-s)/combi(num_total, total_try).to_f
                    x += pp
                end
                x *= [20.0/(1.6**space_size), 1].min
                x = [x, 1.0].min
                hash[[space_size, num_valid, num_total]] = x
                p "#{[space_size, num_valid, num_total]} => #{x}}"
            end
        end
    end
    File.write("default.data", Marshal.dump(hash))
end

def combi(a,b)
    #(1..a).to_a.combination(b).count
    fact(a)/(fact(b)*fact(a-b))
end

def fact(n)
    n.downto(2).inject(1){|t,x|t*x}
end

main()
