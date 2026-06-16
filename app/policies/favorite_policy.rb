# frozen_string_literal: true

class FavoritePolicy < ApplicationPolicy
  def toggle?
    authenticated?
  end
end
