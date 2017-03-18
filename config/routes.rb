Rails.application.routes.draw do


  get 'course/new'
  get 'course/create'
  get 'instructor/new'
  get 'instructor/create'

  resources :assignments
  get 'assignments/new'

  resources :courses
  get 'courses/new'
  
  get 'instructor/enrollStudent'
  post 'instructor/addEnrolledStudent', to: 'instructor#addEnrolledStudent'
  resources :instructor
  get 'instructor/new'
  get 'instructor/index'
  #get 'instructor/enrollStudent', to: 'instructor#enrollStudent'

  
  
  resources :students
  get 'students/new'
  
  
  devise_for :student
  devise_scope :student do
    authenticated :student do
      root 'students#show', as: :authenticated_students_root
    end
    
    authenticated :instructor do
      root 'instructor#show', as: :authenticated_instructor_root
    end
    
    unauthenticated do
      root 'application#index'
    end
  end
  
  devise_for :instructors
  devise_scope :instructor do
    #authenticated :instructor do
      #root 'instructor#show', as: :authenticated_instructor_root
   # end

    unauthenticated do
      root 'application#index'
    end
  end
  


  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root 'application#index'
  

  
end
