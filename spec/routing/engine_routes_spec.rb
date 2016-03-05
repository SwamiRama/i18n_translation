require 'rails_helper'

# A very simple Rails engine
module MyEngine
  class Engine < ::Rails::Engine
    isolate_namespace MyEngine
  end

  Engine.routes.draw do
    resources :widgets, only: [:index]
  end

  class WidgetsController < ::ActionController::Base
    def index
    end
  end
end

RSpec.describe MyEngine::WidgetsController, type: :routing do
  routes { MyEngine::Engine.routes }

  it 'routes to the list of all widgets' do
    expect(get: widgets_path)
      .to route_to(controller: 'my_engine/widgets', action: 'index')
  end
end
