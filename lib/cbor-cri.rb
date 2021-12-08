require 'uri'
require 'ipaddr'
unless defined?(CBOR)
  require 'cbor-pure'
end

class CBOR::CRI

  # index ~n  -1     -2      -3     -4      -5    -6
  SCHEMES = [:coap, :coaps, :http, :https, :urn, :did]

  attr_accessor :scheme, :authority, :discard, :path, :query, :fragment

  def discard?(d)
    true == d || (Integer === d && d >= 0)
  end

  def relpath?
    scheme.nil?
  end

  def initialize(*parts)
    # p parts
    if discard?(parts[0])
      # p 1
      self.discard, self.path, self.query, self.fragment, slop = parts
    else
      if discard?(parts[2])
        # p 2
        self.scheme, self.authority, self.discard, self.path, self.query, self.fragment, slop = parts
      else
        # p 3
        self.scheme, self.authority, self.path, self.query, self.fragment, slop = parts
        self.discard = true
      end
    end
    fail ArgumentError.new(parts.inspect) if slop
    check
  end

  def to_item
    ret =
      if scheme || authority
        fail inspect unless discard == true
        [scheme, authority, path, query, fragment]
      else
        [discard, path, query, fragment]
      end
    while ret.size > 0 && ret[-1].nil?
      ret.pop
    end
    ret
  end

  def ==(other)
    to_item == other.to_item
  end

  # copy?

  def check

  end

  def merge(other)
    ret = dup
    if other.discard == true
      ret.path = other.path.dup
      ret.query = nil
      ret.fragment = nil
      ret.authority = null if ret.authority == true
    elsif Integer === other.discard
      ret.path = ret.path.dup
      ret.path.pop(other.discard)
      ret.path.concat(other.path) if other.path
      if other.discard != 0
        ret.query = nil
        ret.fragment = nil
      end
    end
    if other.scheme
      ret.scheme = other.scheme 
      ret.authority = other.authority
    else
      ret.authority = other.authority if other.authority
    end
    if other.query
      ret.query = other.query 
      ret.fragment = nil
    end
    ret.fragment = other.fragment if other.fragment
    ret
  end

  # XXX percent-encoding needed
  def to_uri
    ret = ""
    if scheme
      ret <<
        if Integer === scheme
          SCHEMES[~scheme].to_s
        else
          scheme
        end << ":"
    end
    if authority && authority != true
      ret << "//" << (host || ":::FAIL:::")
      if port
        ret << ":" << port.to_s
      end
    end
    if path
      ret << "/" if authority != true && discard == true
      ret << path.join("/")
    end
    if query
      ret << "?"
      ret << query.join("&")
    end
    if fragment
      ret << "#"
      ret << fragment
    end
    ret
  end

  # --------------------------------- host/port

  def self.authority_from_host_port(uri)
    if uri.host
      begin
        a = [a_to_n(uri.host)] # XXX platform can't do zone
      rescue IPAddr::InvalidAddressError
        a = uri.host.split(".")
      end
      if Integer === uri.port
        a << uri.port
      end
      a
    end
  end

  def n_to_a(n)
    IPAddr.new_ntoh(n).to_s
  end

  def self.a_to_n(a)
    IPAddr.new(a).hton
  end

  def host
    if authority
      host_a = authority
      if Array === authority
        p = authority.last
        host_a = authority[0...-1] if Integer === p
        return host_a.join(".") if host_a.first.encoding != Encoding::BINARY
        n_to_a(host_a.first)
      end
    end
  end

  def port
    if authority
      if Array === authority
        p = authority.last
        p if Integer === p
      end
    end
  end

  # --------------------------------- URI conversion

  def self.parse_uri_path(uri)
    # !!! check for opaque
    if uri.path
      path = uri.path
    elsif uri.opaque
      path = uri.opaque
    end
    # p path
    if path
      segs = path.split('/', -1).reject {|x| x == '.'}
      if path[0] == '/'
        discard = true
        segs[0..0] = []         # special case
      elsif path == ""
        discard = 0
        segs = nil
      else
        discard = 1             # if no scheme...
        segs = nil if segs == []
      end
      # p segs
      if segs
        opath = []
        # discard = 0             # XXX
        segs.each do |x|
          if x == '..'
            discard += 1 unless opath.pop
          else opath << x
          end
        end
      end
    end
    [uri.opaque ? true : nil, discard, opath]
  end

  def self.from_uri(us)
    if String === us
      us = ::URI.parse(us.force_encoding(Encoding::UTF_8))
    end
    # p us
    if us.scheme || us.host
      authority = authority_from_host_port(us)
      discard = true
    end
    # XXX need to work on host, whether IP address
    opq, dsc, opath = self.parse_uri_path(us)
    # p [opq, dsc, opath, authority]
    query = us.query.split('&') if us.query
    # p opath
    scheme = us.scheme
    if scheme && (a = SCHEMES.index(scheme.intern))
      scheme = ~a
    end
    new(*[scheme, authority || opq, discard || dsc, opath, query, us.fragment])
  end

end
