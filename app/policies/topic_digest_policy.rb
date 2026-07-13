# frozen_string_literal: true

class TopicDigestPolicy < ApplicationPolicy
  def show?
    # Digests are publicly accessible to both logged-in and signed-out users
    true
  end
end
