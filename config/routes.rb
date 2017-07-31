Rails.application.routes.draw do
  get 'game', to: 'word#game'
  get 'score', to: 'word#score'
end
