# -*- coding: utf-8 -*-
class Solver
  def initialize
    # 位置リストを初期化
    @positions = (0..19).to_a
  end

  # numを書き込む場所を返してください。
  # numには0から30の数値が入り、0はワイルドカードです。
  # 書き込む場所は0から19の数値です。
  def on_card(num)
    if num > 15
      @positions.pop
    else
      @positions.shift
    end
  end
end



