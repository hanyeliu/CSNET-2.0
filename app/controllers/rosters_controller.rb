require 'spreadsheet'
class RostersController < ApplicationController
  def index
      @rosters = Roster.all
      roster = Roster.first #Fix this hack later
      Spreadsheet.client_encoding = 'UTF-8'
      book = Spreadsheet.open('public' + roster.attachment_url)
      @sheet1 = book.worksheet 0
      #render :inline => "<%= @sheet1.row(3)[0] %> <br></br> <%= @sheet1.row(3)[2] %>"
      #newStudent = Student.create!(:email => @sheet1.row(1)[2], :password => "password")
      #newStudent.save!
      
      for i in 1..(@sheet1.row_count-1) do
          @instructor = current_instructor
          # find course to add student to 
          @course =  @instructor.courses.find_by( number: roster.course_num )
          # student with this email ( if they exist already ) 
          @student = Student.find_by( email: @sheet1.row(i)[2] )
          
          # A new student is being created
          if @student == nil
            #Ensure students arent enrolled twice
            if @course.students.where( id: @student ).empty? 
              @student = @course.students.create!(:email => @sheet1.row(i)[2], :password => "password")
              @student.save
            end
            #The student already exists
          else
              #Ensure students arent enrolled twice
              if @course.students.where( id: @student ).empty? 
                @course.students << @student
              end
          end
      end
      redirect_to students_path
  end
  
    def new
      @instructor = current_instructor
      @courses = @instructor.courses
      @roster = Roster.new
    end
  
    def create
      @roster = Roster.new(roster_params)
      
      if @roster.save
        redirect_to rosters_path, notice: "The roster #{@roster.course_num} has been uploaded."
      else
        render "new"
      end
    end
  
  private
    def roster_params
      params.require(:roster).permit(:course_num, :attachment)
    end
end