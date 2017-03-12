Rails.application.routes.draw do



  get 'course/new'
  get 'course/create'
  get 'instructor/new'
  get 'instructor/create'
  

  resources :assignments
  get 'assignments/new'

  resources :courses
  get 'courses/new'
  
  resources :instructor
  get 'instructor/new'
  
  resources :student
  get 'student/new'
  
  devise_for :students
  devise_scope :student do
    authenticated :student do
      root 'student#show', as: :authenticated_student_root
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
