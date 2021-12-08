require 'cbor-cri'

class CBOR_DIAG::App_cri
  def self.decode(_, s)
    CBOR::CRI.from_uri(s).to_item
  end
end
