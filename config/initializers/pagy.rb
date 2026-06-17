# frozen_string_literal: true

require "pagy/extras/overflow"
require "pagy/extras/array"

Pagy::DEFAULT[:items] = 10
Pagy::DEFAULT[:overflow] = :last_page
