# frozen_string_literal: true

class PagePolicy < ApplicationPolicy
  def about?
    true
  end

  def privacy?
    true
  end

  def terms?
    true
  end
end
