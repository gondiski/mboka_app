# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_after_action :verify_authorized, raise: false

  def about; end
  def privacy; end
  def terms; end
end
