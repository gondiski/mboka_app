# frozen_string_literal: true

module Hashidable
  extend ActiveSupport::Concern

  def to_param
    HASHIDS.encode(id)
  end

  class_methods do
    def decode_hashid(hashid)
      HASHIDS.decode(hashid).first
    end

    def find_by_hashid(hashid)
      id = decode_hashid(hashid)
      return nil unless id
      find_by(id: id)
    end

    def find_by_hashid!(hashid)
      id = decode_hashid(hashid)
      raise ActiveRecord::RecordNotFound, "Couldn't find record with hashid: #{hashid}" unless id
      find(id)
    end
  end
end
