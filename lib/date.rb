class Date
  # Convert a Commercial Date to a Julian Day Number.
  #
  # +y+, +w+, and +d+ are the (broadcast) year, week of the year,
  # and day of the week of the Broadcast Date to convert.
  # +sg+ specifies the Day of Calendar Reform.
  def self.broadcast_to_jd(y, w, d, ns=GREGORIAN)
    jd = self == Date ? civil_to_jd(y, 1, 1, ns) - civil(y, 1, 1, ns).wday : civil_to_jd(y, 1, 1, ns) - civil(y, 1, 1, 0, 0, 0, 0, ns).wday
    (jd - (((jd - 1) + 1) % 7)) +
      7 * (w) +
      (d - 1)
  end

  # Convert a Julian Day Number to a Broadcast Date
  #
  # +jd+ is the Julian Day Number to convert.
  # +sg+ specifies the Day of Calendar Reform.
  #
  # Returns the corresponding Broadcast Date as
  # [commercial_year, week_of_year, day_of_week]
  def self.jd_to_broadcast(jd, sg=GREGORIAN)
    ns = fix_style(jd, sg)
    a = jd_to_civil(jd - 3, ns)[0]
    y = if jd >= broadcast_to_jd(a + 1, 1, 1, ns) then a + 1 else a end
    w = 1 + ((jd - broadcast_to_jd(y, 1, 1, ns)) / 7).floor
    d = (jd + 1) % 7
    d = 7 if d == 0
    return y, w, d
  end

  def self.bweeknum_to_jd(y, w, d, f=0, ns=GREGORIAN) # :nodoc:
    a = civil_to_jd(y, 1, 1, ns) + 6
    (a - ((a - f) + 1) % 7 - 7) + 7 * w + d
  end

  def self.jd_to_bweeknum(jd, f=0, sg=GREGORIAN) # :nodoc:
    ns = fix_style(jd, sg)
    y, m, d = jd_to_civil(jd, ns)
    a = civil_to_jd(y, 1, 1, ns) + 6
    w, d = (jd - (a - ((a - f) + 1) % 7) + 7).divmod(7)
    return y, w, d
  end

  private_class_method :bweeknum_to_jd, :jd_to_bweeknum

  # Do year +y+, week-of-year +w+, and day-of-week +d+ make a
  # valid Broadcast Date?  Returns the corresponding Julian
  # Day Number if they do, nil if they don't.
  #
  # Monday is day-of-week 1; Sunday is day-of-week 7.
  #
  # +w+ and +d+ can be negative, in which case they count
  # backwards from the end of the year and the end of the
  # week respectively.  No wraparound is performed, however,
  # and invalid values cause an ArgumentError to be raised.
  # A date falling in the period skipped in the Day of Calendar
  # Reform adjustment is not valid.
  #
  # +sg+ specifies the Day of Calendar Reform.
  def self.valid_broadcast? (y, w, d, sg=ITALY)
    if d < 0
      d += 8
    end
    if w < 0
      ny, nw, nd =
        jd_to_broadcast(broadcast_to_jd(y + 1, 1, 1) + w * 7)
      return unless ny == y
      w = nw
    end
    jd = broadcast_to_jd(y, w, d)
    return unless gregorian?(jd, sg)
    return unless [y, w, d] == jd_to_broadcast(jd)
    jd
  end

  def self.valid_bweeknum? (y, w, d, f, sg=ITALY) # :nodoc:
    if d < 0
      d += 7
    end
    if w < 0
      ny, nw, nd, nf =
        jd_to_bweeknum(bweeknum_to_jd(y + 1, 1, f, f) + w * 7, f)
      return unless ny == y
      w = nw
    end
    jd = bweeknum_to_jd(y, w, d, f)
    return unless gregorian?(jd, sg)
    return unless [y, w, d] == jd_to_bweeknum(jd, f)
    jd
  end

  private_class_method :valid_bweeknum?

  # Create a new Date object for the Broadcast Date specified by
  # year +y+, week-of-year +w+, and day-of-week +d+.
  #
  # Monday is day-of-week 1; Sunday is day-of-week 7.
  #
  # +w+ and +d+ can be negative, in which case they count
  # backwards from the end of the year and the end of the
  # week respectively.  No wraparound is performed, however,
  # and invalid values cause an ArgumentError to be raised.
  #
  # +y+ defaults to 1582, +w+ to 41, and +d+ to 5, the Day of
  # Calendar Reform for Italy and the Catholic countries.
  #
  # +sg+ specifies the Day of Calendar Reform.
  def self.broadcast(y=1582, w=41, d=5, sg=ITALY)
    unless jd = valid_broadcast?(y, w, d, sg)
      raise ArgumentError, 'invalid date'
    end
    new!(jd_to_ajd(jd, 0, 0), 0, sg)
  end

  def self.bweeknum(y=1582, w=41, d=5, f=0, sg=ITALY) # :nodoc:
    unless jd = valid_bweeknum?(y, w, d, f, sg)
      raise ArgumentError, 'invalid date'
    end
    new!(jd_to_ajd(jd, 0, 0), 0, sg)
  end

  private_class_method :bweeknum

  def self.complete_frags(elem) # :nodoc:
    i = 0
    g = [[:time, [:hour, :min, :sec]],
      [nil, [:jd]],
      [:ordinal, [:year, :yday, :hour, :min, :sec]],
      [:civil, [:year, :mon, :mday, :hour, :min, :sec]],
      [:commercial, [:cwyear, :cweek, :cwday, :hour, :min, :sec]],
      [:broadcast, [:bwyear, :bweek, :bwday, :hour, :min, :sec]],
      [:wday, [:wday, :hour, :min, :sec]],
      [:wnum0, [:year, :wnum0, :wday, :hour, :min, :sec]],
      [:wnum1, [:year, :wnum1, :wday, :hour, :min, :sec]],
      [:bwday, [:bwday, :hour, :min, :sec]],
      [:bwnum0, [:year, :bwnum0, :bwday, :hour, :min, :sec]],
      [:bwnum1, [:year, :bwnum1, :bwday, :hour, :min, :sec]],
      [nil, [:cwyear, :cweek, :wday, :hour, :min, :sec]],
      [nil, [:bwyear, :bweek, :wday, :hour, :min, :sec]],
      [nil, [:year, :wnum0, :cwday, :hour, :min, :sec]],
      [nil, [:year, :wnum1, :cwday, :hour, :min, :sec]],
      [nil, [:year, :bwnum0, :bwday, :hour, :min, :sec]],
      [nil, [:year, :bwnum1, :bwday, :hour, :min, :sec]]
    ].
      collect{|k, a| e = elem.values_at(*a).compact; [k, a, e]}.
      select{|k, a, e| e.size > 0}.
      sort_by{|k, a, e| [e.size, i -= 1]}.last

    d = nil

    if g && g[0] && (g[1].size - g[2].size) != 0
      d ||= Date.today

      case g[0]
      when :ordinal
        elem[:year] ||= d.year
        elem[:yday] ||= 1
      when :civil
        g[1].each do |e|
          break if elem[e]
          elem[e] = d.__send__(e)
        end
        elem[:mon]  ||= 1
        elem[:mday] ||= 1
      when :commercial
        g[1].each do |e|
          break if elem[e]
          elem[e] = d.__send__(e)
        end
        elem[:cweek] ||= 1
        elem[:cwday] ||= 1
      when :broadcast
        g[1].each do |e|
          break if elem[e]
          elem[e] = d.__send__(e)
        end
        elem[:bweek] ||= 1
        elem[:bwday] ||= 1
      when :wday
        elem[:jd] ||= (d - d.wday + elem[:wday]).jd
      when :bwday
        elem[:jd] ||= (d - d.wday + elem[:bwday]).jd
      when :wnum0
        g[1].each do |e|
          break if elem[e]
          elem[e] = d.__send__(e)
        end
        elem[:wnum0] ||= 0
        elem[:wday]  ||= 0
      when :bwnum1
        g[1].each do |e|
          break if elem[e]
          elem[e] = d.__send__(e)
        end
        elem[:bwnum1] ||= 0
        elem[:bwday]  ||= 0
      when :bwnum0
        g[1].each do |e|
          break if elem[e]
          elem[e] = d.__send__(e)
        end
        elem[:bwnum0] ||= 0
        elem[:bwday]  ||= 0
      when :bwnum1
        g[1].each do |e|
          break if elem[e]
          elem[e] = d.__send__(e)
        end
        elem[:bwnum1] ||= 0
        elem[:bwday]  ||= 0
      end
    end

    if g && g[0] == :time
      if self <= DateTime
        d ||= Date.today
        elem[:jd] ||= d.jd
      end
    end

    elem[:hour] ||= 0
    elem[:min]  ||= 0
    elem[:sec]  ||= 0
    elem[:sec] = [elem[:sec], 59].min

    elem
  end

  private_class_method :complete_frags

  def self.valid_date_frags?(elem, sg) # :nodoc:
    catch :jd do
      a = elem.values_at(:jd)
      if a.all?
        if jd = valid_jd?(*(a << sg))
          throw :jd, jd
        end
      end

      a = elem.values_at(:year, :yday)
      if a.all?
        if jd = valid_ordinal?(*(a << sg))
          throw :jd, jd
        end
      end

      a = elem.values_at(:year, :mon, :mday)
      if a.all?
        if jd = valid_civil?(*(a << sg))
          throw :jd, jd
        end
      end

      a = elem.values_at(:cwyear, :cweek, :cwday)
      if a[2].nil? && elem[:wday]
        a[2] = elem[:wday].nonzero? || 7
      end
      if a.all?
        if jd = valid_commercial?(*(a << sg))
          throw :jd, jd
        end
      end

      a = elem.values_at(:bwyear, :bweek, :bwday)
      if a[2].nil? && elem[:bwday]
        a[2] = elem[:bwday].nonzero? || 7
      end
      if a.all?
        if jd = valid_broadcast?(*(a << sg))
          throw :jd, jd
        end
      end

      a = elem.values_at(:year, :wnum0, :wday)
      if a[2].nil? && elem[:cwday]
        a[2] = elem[:cwday] % 7
      end
      if a.all?
        if jd = valid_weeknum?(*(a << 0 << sg))
          throw :jd, jd
        end
      end

      a = elem.values_at(:year, :bwnum0, :bwday)
      if a[2].nil? && elem[:bwday]
        a[2] = elem[:bwday] % 7
      end
      if a.all?
        if jd = valid_bweeknum?(*(a << 0 << sg))
          throw :jd, jd
        end
      end

      a = elem.values_at(:year, :wnum1, :wday)
      if a[2]
        a[2] = (a[2] - 1) % 7
      end
      if a[2].nil? && elem[:cwday]
        a[2] = (elem[:cwday] - 1) % 7
      end
      if a.all?
        if jd = valid_weeknum?(*(a << 1 << sg))
          throw :jd, jd
        end
      end

      a = elem.values_at(:year, :bwnum1, :bwday)
      if a[2]
        a[2] = (a[2] - 1) % 7
      end
      if a[2].nil? && elem[:bwday]
        a[2] = (elem[:bwday] - 1) % 7
      end
      if a.all?
        if jd = valid_bweeknum?(*(a << 1 << sg))
          throw :jd, jd
        end
      end
    end
  end

  private_class_method :valid_date_frags?



  # Get the date as a Broadcast Date, [year, week_of_year, day_of_week]
  def broadcast() self.class.jd_to_broadcast(jd, @sg) end # :nodoc:

  def bweeknum0() self.class.__send__(:jd_to_bweeknum, jd, 0, @sg) end # :nodoc:
  def bweeknum1() self.class.__send__(:jd_to_bweeknum, jd, 1, @sg) end # :nodoc:

  once :broadcast, :bweeknum0, :bweeknum1
  private :broadcast, :bweeknum0, :bweeknum1

  def bwnum0() bweeknum0[1] end # :nodoc:
  def bwnum1() bweeknum1[1] end # :nodoc:

  private :bwnum0, :bwnum1

  # Get the broadcast year of this date.  See *Broadcast* *Date*
  # in the introduction for how this differs from the normal year.
  def bwyear() broadcast[0] end

  # Get the broadcast week of the year of this date.
  def bweek() broadcast[1] end

  # Get the broadcast day of the week of this date.  Monday is
  # broadcast day-of-week 1; Sunday is broadcast day-of-week 7.
  def bwday() broadcast[2] end
end
class DateTime < Date

  # Create a new DateTime object corresponding to the specified
  # Commercial Date and hour +h+, minute +min+, second +s+.
  #
  # The 24-hour clock is used.  Negative values of +h+, +min+, and
  # +sec+ are treating as counting backwards from the end of the
  # next larger unit (e.g. a +min+ of -2 is treated as 58).  No
  # wraparound is performed.  If an invalid time portion is specified,
  # an ArgumentError is raised.
  #
  # +of+ is the offset from UTC as a fraction of a day (defaults to 0).
  # +sg+ specifies the Day of Calendar Reform.
  #
  # +y+ defaults to 1582, +w+ to 41, and +d+ to 5; this is the Day of
  # Calendar Reform for Italy and the Catholic countries.
  # The time values default to 0.
  def self.broadcast(y=1582, w=41, d=5, h=0, min=0, s=0, of=0, sg=ITALY)
    unless (jd = valid_broadcast?(y, w, d, sg)) &&
        (fr = valid_time?(h, min, s))
      raise ArgumentError, 'invalid date'
    end
    if String === of
      of = Rational(zone_to_diff(of) || 0, 86400)
    end
    new!(jd_to_ajd(jd, fr, of), of, sg)
  end

  def self.bweeknum(y=1582, w=41, d=5, f=0, h=0, min=0, s=0, of=0, sg=ITALY) # :nodoc:
    unless (jd = valid_bweeknum?(y, w, d, f, sg)) &&
        (fr = valid_time?(h, min, s))
      raise ArgumentError, 'invalid date'
    end
    if String === of
      of = Rational(zone_to_diff(of) || 0, 86400)
    end
    new!(jd_to_ajd(jd, fr, of), of, sg)
  end

  private_class_method :bweeknum



end
