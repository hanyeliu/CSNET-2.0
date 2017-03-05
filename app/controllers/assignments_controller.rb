class AssignmentsController < ApplicationController
  def new
    @instructor = current_instructor
    @courses = Course.where( instructor_id: @instructor)
  end

  def create
    #@instructor.courses.create
    @course = Course.find_by number: (params[:assignment][:course_num].to_i)
      
    
    if (@course != nil)
      @assignment = @course.assignments.create(assignment_params)
      redirect_to @assignment
    else
      redirect_to assignments_path
    end
      
      
  end
  
  def delete
    if (@course != nil)
      @assignment = @course.assignments.delete(assignment_params)
      redirect_to assignments_path
    else
      redirect_to assignments_path
    end
  end
  
  def index
    @assignments = Assignment.all
  end

  def show
    @assignment = Assignment.find(params[:id])
  end

  def edit
    @instructor = current_instructor
    @courses = Course.where( instructor_id: @instructor)
    @assignment = Assignment.find(params[:id])
  end
  
  def update
    @assignment = Assignment.find(params[:id])
    if @assignment.update(assignment_params)
       redirect_to @assignment
    else
       render 'edit'
    end
  end
    
  def destroy
      @assignment = Assignment.find(params[:id])
      @assignment.destroy
      redirect_to assignments_path, notice:  "The assignment #{@assignment.name} has been deleted."
   end
    
    
  private
    def assignment_params
      params.require(:assignment).permit(:name, :due_date, :course_num,:attachment)
    end
end