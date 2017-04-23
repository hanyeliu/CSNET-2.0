require 'rubygems'
require 'zip'
require 'aws-sdk' # not 'aws-sdk'
class SubmissionsController < ApplicationController
   
    def index
      @isInstructor  = false
      @isAssistant   = false
      @isStudent     = false
      if(instructor_signed_in?)
        @courses = current_instructor.courses
        @isInstructor = true
      elsif (assistant_signed_in?)
        @courses = current_assistant.courses
        @isAssistant = true
      elsif (student_signed_in?)
        @courses = current_student.courses
        @isStudent = true
      else 
        redirect_to root_path
        return
      end
      
        @courses.each do |course|
          if (@assignments == nil)
            @assignments = course.assignments.all
          else
            @assignments = @assignments + course.assignments.all
          end
        end
      
        @assignments.each do |assignment|
          if (@submissions == nil)
            @submissions = assignment.submissions.all
          else
            @submissions = @submissions + assignment.submissions.all
          end
        end
        
        if student_signed_in?
            @submissions = Submission.where( student_id: current_student )
        end
    end

   
   def new
       if not student_signed_in?
          redirect_to root_path
          return
       end
      @student = current_student
      @isInstructor  = false
      @isAssistant   = false
      @isStudent     = true

      @submission = Submission.new
      @courses = @student.courses
      @assignments = nil
      @courses.each do |course|
        if (@assignments == nil)
          @assignments = course.assignments.all
        else
          @assignments = @assignments + course.assignments.all
        end
      end
   end
   
   
 def create
  if not student_signed_in?
     redirect_to root_path
     return
  end
  
  @student = current_student
  
  @currentTime = Time.now
  @currentMonth = @currentTime.month
  @currentYear = @currentTime.year
  
  if( @currentMonth >= 1 && @currentMonth <= 5 )
    @session = "SPRING"
  elsif( @currentMonth >= 6 && (@currentMonth < 8 || (@currentMonth == 8 && @currentDay <= 11)) ) 
    @session = "SUMMER"
  else 
    @session = "FALL"
  end 
  
  # Check if that course exists
  @course = current_student.courses.where( number: params[:submission][:course_num], year: @currentYear.to_s, session: @session ).first
  if (@course == nil) 
    flash[:danger] = "Could not submit because the corresponding course was not found."
    redirect_to root_path
    return
  end 
  
  @assignment = @course.assignments.find_by(name: params[:submission][:assignment])
  if (@assignment == nil) 
    flash[:danger] = "Could not submit because the corresponding assignment was not found."
    redirect_to root_path
    return
  end 
  
  # store the file as something unique otherwise unable to distinguish between
  # two student submissions with the same name
  orig_name = params[:submission][:attachment].original_filename
  # to distinguish between a file submited by the same student with the 'original_filename'
  subCount = Submission.maximum(:id)
  if subCount == nil
    subCount = 1
  else
    subCount += 1
  end
  params[:submission][:attachment].original_filename = "#{@student.last_name}_#{@student.first_name}_#{@student.id}_#{subCount}_#{orig_name}"
  
  @submission = @student.submissions.create(name: params[:submission][:name], 
                                        attachment: params[:submission][:attachment],
                                        assignment: @assignment)

  if @submission.save
      flash[:success] = "The assignment #{@submission.name} has been submitted successfully"
      
      # send an acknowldegment email that the submission was turned in successfully
      UserMailer.ack_submission(@student, @submission, @course, @assignment).deliver_later
      redirect_to submissions_path
  else
      flash[:danger] = "Assignment was not submited successfuly. Please try again"
      redirect_to submissions_path
  end
 end
   
   def destroy
       if not student_signed_in?
           redirect_to root_path
           return
       end
      @submission = Submission.find(params[:id])
      
      # make sure student who made submission is one destroying it
      if not (@submission.student == current_student)
          redirect_to root_path
          return
      end
      
      @submission.destroy
      redirect_to submissions_path, notice:  "The submission #{@submission.name} has been deleted."
   end
  
  def download

    # first find the course that we want to download the submissions for
    @course_chosen = Course.find(params[:submission][:course_id])

    # the assignment we want to get submissions for
    @assignment_chosen = Assignment.find_by(name: params[:submission][:assignment])

    # get all the submissions for that assignment
    @all_submissions = Submission.where(assignment_id: @assignment_chosen.id)

    # limit submissions to only new the newest ones
    newest_submissions = []
    for i in 0 .. @all_submissions.size-1
        dupSubFound = false
        dupIndex = -1
        sub = @all_submissions[i]
        stud_id = sub.student_id
      for j in 0 .. newest_submissions.size-1
        if (stud_id == newest_submissions[j].student_id)
          dupSubFound = true
          dupIndex = j
          break
        end
      end
      if dupSubFound == false
        # the first encountered submission of a particular student
        newest_submissions.push(sub)
      else
        # keep only the newest submission
      
        # find the students other submission
        dupSub = newest_submissions[dupIndex]

        # keep only the newest one
        if (dupSub.created_at > sub.created_at)
          # the newest submission is already in the list
        else
          # replace the submission
          newest_submissions[dupIndex] = sub
        end
      end
    end
        
    # get all the attachment names for that assignment (b/c we only store the attachmetn on aws)
    # note: escape https://431storage.s3.amazonaws.com/ since not needed
    @desired_attachment_names = newest_submissions.map{ |sub| sub.attachment_url[36..-1] }


    # configure aws
    Aws.config.update({
      region: 'us-east-1',
      access_key_id: ENV['ACCESS_KEY_ID'],
      secret_access_key: ENV['SECRET_ACCESS_KEY']
    })
    
    s3 = Aws::S3::Resource.new
    # the bucket where submissions are stored
    bucket = s3.bucket("431storage")
  
    # These are all the files in the bucket - for testing purposes
    #files_in_bucket = bucket.objects(prefix: '').collect(&:key)
    #puts "putting "
    #puts files_in_bucket

    
    # files downloaded first to local folder in temp dir
    # it will get deleted when this function ends
    local_folder = "tmp/submissions"

    # first check if folder exists. if not make it.
    Dir.mkdir(local_folder) unless File.exists?(local_folder)

    # the files to download 
    files = @desired_attachment_names

    # Download the files from S3 to a local folder
    files.each do |file_name|
      # Get the file object
      file_obj = bucket.object("#{file_name}")
      # Save it on disk
      file_obj.get(response_target: "#{local_folder}/#{file_name}")
    end

    # after files have been downloaded zip to this file
    zipfile_name = "submissions.zip"

    # create a temp folder for this zip file. it will also get deleted
    temp_file = Tempfile.new(zipfile_name)
     
    begin
      # Initialize the temp file as a zip file
      Zip::OutputStream.open(temp_file) { |zos| }
     
      # Open a zip file
      Zip::File.open(temp_file.path, Zip::File::CREATE) do |zip| 
        files.each do |filename|
          # add files to the zip
          zip.add(filename, temp_file.path)
        end
      end
     
      #Read the binary data from the file
      zip_data = File.read(temp_file.path)
     
      #Send the data to the browser as an attachment
      #We do not send the file directly because it will
      #get deleted before rails actually starts sending it
      send_data(zip_data, :type => 'application/zip', :filename => zipfile_name)
    ensure

      #Close and delete the downloaded zip file (was stored in temp dir.)
      temp_file.close
      temp_file.unlink
      
      # delete the local folder that had the submissions downloaded
      FileUtils.rm_rf("#{local_folder}")
    end

    # success
  end


    helper_method :download 

   private
    def submission_params
      params.require(:submission).permit(:name, :assignment, :attachment)
    end
end
