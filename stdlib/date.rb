class Date
  class Infinity < Numeric
    include Comparable

    def initialize(d = 1)
      @d = d <=> 0
    end

    def d
      @d
    end

    def zero?
      false
    end

    def finite?
      false
    end

    def infinite?
      d.nonzero?
    end

    def nan?
      d.zero?
    end

    def abs
      self.class.new
    end

    def -@
      self.class.new(-d)
    end

    def +@
      self.class.new(+d)
    end

    def <=> (other)
      case other
      when Infinity; return d <=> other.d
      when Numeric; return d
      else
        begin
          l, r = other.coerce(self)
          return l <=> r
        rescue NoMethodError
        end
      end
      nil
    end

    def coerce(other)
      case other
      when Numeric
        return -d, d
      else
        super
      end
    end

    def to_f
      return 0 if @d == 0
      if @d > 0
        Float::INFINITY
      else
        -Float::INFINITY
      end
    end
  end

  JULIAN        = Infinity.new
  GREGORIAN     = -Infinity.new
  ITALY         = 2299161 # 1582-10-15
  ENGLAND       = 2361222 # 1752-09-14
  MONTHNAMES    = [nil] + %w(January February March April May June July August September October November December)
  DAYNAMES      = %w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)
  ABBR_DAYNAMES = %w(Sun Mon Tue Wed Thu Fri Sat)

  class << self
    alias civil new

    def wrap(native)
      instance = allocate
      `#{instance}.date = #{native}`
      instance
    end

    def parse(string)
      match = `/^(\d*)-(\d*)-(\d*)/.exec(string)`
      wrap `new Date(parseInt(match[1], 10), parseInt(match[2], 10) - 1, parseInt(match[3], 10))`
    end

    def today
      wrap `new Date()`
    end
  end

  def initialize(year = -4712, month = 1, day = 1, start = ITALY)
    @date = `new Date(year, month - 1, day)`
  end

  def -(date)
    %x{
      if (date.$$is_number) {
        var result = #{clone};
        result.date.setDate(#@date.getDate() - date);
        return result;
      }
      else if (date.date) {
        return Math.round((#@date - #{date}.date) / (1000 * 60 * 60 * 24));
      }
      else {
        #{raise TypeError};
      }
    }
  end

  def +(date)
    %x{
      if (date.$$is_number) {
        var result = #{clone};
        result.date.setDate(#@date.getDate() + date);
        return result;
      }
      else {
        #{raise TypeError};
      }
    }
  end

  def <(other)
    %x{
      var a = #@date, b = #{other}.date;
      a.setHours(0, 0, 0, 0);
      b.setHours(0, 0, 0, 0);
      return a < b;
    }
  end

  def <=(other)
    %x{
      var a = #@date, b = #{other}.date;
      a.setHours(0, 0, 0, 0);
      b.setHours(0, 0, 0, 0);
      return a <= b;
    }
  end

  def >(other)
    %x{
      var a = #@date, b = #{other}.date;
      a.setHours(0, 0, 0, 0);
      b.setHours(0, 0, 0, 0);
      return a > b;
    }
  end

  def >=(other)
    %x{
      var a = #@date, b = #{other}.date;
      a.setHours(0, 0, 0, 0);
      b.setHours(0, 0, 0, 0);
      return a >= b;
    }
  end

  def <=>(other)
    %x{
      var a = #@date, b = #{other}.date;
      a.setHours(0, 0, 0, 0);
      b.setHours(0, 0, 0, 0);

      if (a < b) {
        return -1;
      }
      else if (a > b) {
        return 1;
      }
      else {
        return 0;
      }
    }
  end

  def ==(other)
    %x{
      var a = #@date, b = other.date;
      return (a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate());
    }
  end

  def >>(n)
    %x{
      if (!n.$$is_number) {
        #{raise TypeError};
      }

      var result = #{clone}, date = result.date, cur = date.getDate();
      date.setDate(1);
      date.setMonth(date.getMonth() + n);
      date.setDate(Math.min(cur, days_in_month(date.getFullYear(), date.getMonth())));
      return result;
    }
  end

  def <<(n)
    %x{
      if (!n.$$is_number) {
        #{raise TypeError};
      }

      return #{self >> `-n`};
    }
  end

  alias eql? ==

  def clone
    Date.wrap(`new Date(#@date.getTime())`)
  end

  def day
    `#@date.getDate()`
  end

  def friday?
    wday == 5
  end

  def jd
    %x{
    //Adapted from http://www.physics.sfasu.edu/astro/javascript/julianday.html

    var mm = #@date.getMonth() + 1,
        dd = #@date.getDate(),
        yy = #@date.getFullYear(),
        hr = 12, mn = 0, sc = 0,
        ggg, s, a, j1, jd;

    hr = hr + (mn / 60) + (sc/3600);

    ggg = 1;
    if (yy <= 1585) {
      ggg = 0;
    }

    jd = -1 * Math.floor(7 * (Math.floor((mm + 9) / 12) + yy) / 4);

    s = 1;
    if ((mm - 9) < 0) {
      s =- 1;
    }

    a = Math.abs(mm - 9);
    j1 = Math.floor(yy + s * Math.floor(a / 7));
    j1 = -1 * Math.floor((Math.floor(j1 / 100) + 1) * 3 / 4);

    jd = jd + Math.floor(275 * mm / 9) + dd + (ggg * j1);
    jd = jd + 1721027 + 2 * ggg + 367 * yy - 0.5;
    jd = jd + (hr / 24);

    return jd;
    }
  end

  def julian?
    `#@date < new Date(1582, 10 - 1, 15, 12)`
  end

  def monday?
    wday == 1
  end

  def month
    `#@date.getMonth() + 1`
  end

  def next
    self + 1
  end

  def next_day(n=1)
    self + n
  end

  def next_month
    %x{
      var result = #{clone}, date = result.date, cur = date.getDate();
      date.setDate(1);
      date.setMonth(date.getMonth() + 1);
      date.setDate(Math.min(cur, days_in_month(date.getFullYear(), date.getMonth())));
      return result;
    }
  end

  def prev_day(n=1)
    self - n
  end

  def prev_month
    %x{
      var result = #{clone}, date = result.date, cur = date.getDate();
      date.setDate(1);
      date.setMonth(date.getMonth() - 1);
      date.setDate(Math.min(cur, days_in_month(date.getFullYear(), date.getMonth())));
      return result;
    }
  end

  def saturday?
    wday == 6
  end

  def strftime(format = '')
    %x{
      if (format == '') {
        return #{to_s};
      }

      return #@date.$strftime(#{format});
    }
  end

  alias_method :succ, :next

  def sunday?
    wday == 0
  end

  def thursday?
    wday == 4
  end

  def to_s
    %x{
      var d = #@date, year = d.getFullYear(), month = d.getMonth() + 1, day = d.getDate();
      if (month < 10) { month = '0' + month; }
      if (day < 10) { day = '0' + day; }
      return year + '-' + month + '-' + day;
    }
  end

  def tuesday?
    wday == 2
  end

  def wday
    `#@date.getDay()`
  end

  def wednesday?
    wday == 3
  end

  def year
    `#@date.getFullYear()`
  end

  %x{
    function days_in_month(year, month) {
      var leap = ((year % 4 === 0 && year % 100 !== 0) || year % 400 === 0);
      return [31, (leap ? 29 : 28), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month]
    }
  }
end
