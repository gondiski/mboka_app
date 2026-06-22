# frozen_string_literal: true

class Admin::DocsController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize :docs, :show?, policy_class: Admin::DocsPolicy
  end
end
