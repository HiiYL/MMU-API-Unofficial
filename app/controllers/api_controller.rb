class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_filter :set_agent
  def update_bulletin
    Bulletin.update_bulletin
    render json: JSON.pretty_generate( Bulletin.order(posted_on: :desc,url: :desc).limit(20).as_json)
  end

  def test
  end

  def mmls
    page = @agent.get("https://mmls.mmu.edu.my")
    form = page.form
    form.stud_id = params[:student_id]
    form.stud_pswrd = params[:password]


    page = @agent.submit(form)
    if page.parser.xpath('//*[@id="alert"]').empty?
      subject_links = page.links_with(:text => /[A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9] . [A-Z][A-Z]/)
      @subjects = []
      files = []
      subject_links.each do |link|
        if true
          page = @agent.get(link.uri)
          original = page.parser.xpath('/html/body/div[1]/div[3]/div/div/div/div[1]')
          subject_name = link.text
          subject ||= Subject.new
          subject.name = subject_name
          week_number = 1
          while !page.parser.xpath("//*[@id='accordion']/div[#{week_number}]/div[1]/h3/a").empty? do
            week = subject.weeks.build
            week.title = page.parser.xpath("//*[@id='accordion']/div[#{week_number}]/div[1]/h3/a").text.delete("\r").delete("\n").delete("\t").split(" - ")[0]
            announcement_number = 1
            announcement_generic_path = page.parser.xpath("//*[@id='accordion']/div[#{week_number}]/div[2]/div/div/div[1]")
            while !announcement_generic_path.xpath("div[#{announcement_number}]/font").empty? do
              announcement = week.announcements.build
              announcement.title = announcement_generic_path.xpath("div[#{announcement_number}]/font").inner_text.delete("\r").delete("\t")
              announcement.contents = announcement_generic_path.xpath("div[#{announcement_number}]")
              announcement.contents.gsub!('src="', 'src="https://mmls.mmu.edu.my/')
              announcement.author = announcement_generic_path.xpath("div[#{announcement_number}]/div[1]/i[1]").text.delete("\r").delete("\n").delete("\t").split("  ;   ").first[3..-1]
              announcement.posted_date = announcement_generic_path.xpath("div[#{announcement_number}]/div[1]/i[1]").text.delete("\r").delete("\n").delete("\t").split("               ").last
              if !announcement_generic_path.xpath("div[#{announcement_number}]").at('form').nil?
                form_nok = announcement_generic_path.xpath("div[#{announcement_number}]").at('form')
                form = Mechanize::Form.new form_nok, @agent, page
                file_details_hash =  Hash[form.keys.zip(form.values)]
                file = announcement.subject_files.build
                file.file_name = file_details_hash["file_name"]
                file.token = file_details_hash["_token"]
                file.content_id = file_details_hash["content_id"]
                file.content_type = file_details_hash["content_type"]
                file.file_path = file_details_hash["file_path"]
              end

              announcement_number = announcement_number + 1
            end
            week_number = week_number + 1
          end
          download_forms = page.forms_with(:action => 'https://mmls.mmu.edu.my/form-download-content')
          download_forms.each do |form|
            file_details_hash =  Hash[form.keys.zip(form.values)]
            file = subject.subject_files.build
            file.file_name = file_details_hash["file_name"]
            file.token = file_details_hash["_token"]
            file.content_id = file_details_hash["content_id"]
            file.content_type = file_details_hash["content_type"]
            file.file_path = file_details_hash["file_path"]
          end
          # subject.save
        end
        @subjects << subject
      end
      cookies[:laravel_session] = @agent.cookie_jar.first.value
      respond_to do |format|
        format.json do
          render :json => JSON.pretty_generate(@subjects.as_json(
              :include => [{ :weeks => {
              :include => {:announcements => {:include => :subject_files} } }}, :subject_files]))
        end
        format.js 
      end
    else
      render json: {error: "Incorrect MMLS username or password"}, status: 400
    end
  end

  def refresh_token
    page = @agent.get("https://mmls.mmu.edu.my")
    form = page.form
    token = form._token
    form.stud_id = params[:student_id]
    form.stud_pswrd = params[:password]
    page = @agent.submit(form)
    laravel_cookie = @agent.cookie_jar.first.value
    render json: {token: form._token, cookie: laravel_cookie}
  end

  def login_camsys_v2
    @agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    page = @agent.get("https://cms.mmu.edu.my/psp/csprd/?&cmd=login&languageCd=ENG")
    form = page.form
    form.userid = params[:student_id]
    form.pwd = params[:camsys_password]
    page = @agent.submit(form)
    if page.parser.xpath('//*[@id="login_error"]').empty?
      response = {}
      page = @agent.get("https://cms.mmu.edu.my/psc/csprd/EMPLOYEE/HRMS/c/N_SR_STUDENT_RECORDS.N_SR_SS_ATTEND_PCT.GBL?
        PORTALPARAM_PTCNAV=HC_SSS_attendance_PERCENT_GBL&EOPP.SCNode=HRMS&EOPP.SCPortal=EMPLOYEE&EOPP.SCName=
        CO_EMPLOYEE_SELF_SERVICE&EOPP.SCLabel=Self%20Service&EOPP.SCPTfname=CO_EMPLOYEE_SELF_SERVICE&FolderPath=
        PORTAL_ROOT_OBJECT.CO_EMPLOYEE_SELF_SERVICE.HCCC_ACADEMIC_RECORDS.HC_SSS_attendance_PERCENT_GBL&IsFolder=
        false&PortalActualURL=https%3a%2f%2fcms.mmu.edu.my%2fpsc%2fcsprd%2fEMPLOYEE%2fHRMS%2fc%2fN_SR_STUDENT_RECORDS.
        _SR_SS_ATTEND_PCT.GBL&PortalContentURL=https%3a%2f%2fcms.mmu.edu.my%2fpsc%2fcsprd%2fEMPLOYEE%2fHRMS%2fc%
        2fN_SR_STUDENT_RECORDS.N_SR_SS_ATTEND_PCT.GBL&PortalContentProvider=HRMS&PortalCRefLabel=attendance%
        20Percentage%20by%20class&PortalRegistryName=EMPLOYEE&PortalServletURI=https%3a%2f%2fcms.mmu.edu.my
        %2fpsp%2fcsprd%2f&PortalURI=https%3a%2f%2fcms.mmu.edu.my%2fpsc%2fcsprd%2f&PortalHostNode=HRMS&NoCrumbs=yes
        &PortalKeyStruct=yes")
      subjects_attendance = []
      attendance_table = page.parser.xpath('//*[@id="N_STN_ENRL_SSVW$scroll$0"]')
      attendance_table_fields = attendance_table.xpath("tr[2]").text.split("\n").reject!(&:empty?)
      current_row = 3
      while(!attendance_table.xpath("tr[#{current_row}]").empty? ) do
        subject_row = attendance_table.xpath("tr[#{current_row}]").text.split("\n").reject!(&:empty?)
        subject_is_not_barred = attendance_table.xpath("tr[#{current_row}]/td[6]/div/input").attr('value').value == "Y"? "false" : "true"
        subject_row.insert(5, subject_is_not_barred)
        subjects_attendance << Hash[attendance_table_fields.zip(subject_row)]
        current_row = current_row + 1
      end
      response[:subjects_attendance] = subjects_attendance
      page = @agent.get("https://cms.mmu.edu.my/psc/csprd/EMPLOYEE/HRMS/c/SA_LEARNER_SERVICES.N_SSF_ACNT_SUMMARY.GBL?
        PORTALPARAM_PTCNAV=N_SSF_ACNT_SUMMARY_GBL&EOPP.SCNode=HRMS&EOPP.SCPortal=EMPLOYEE&EOPP.SCName=
        CO_EMPLOYEE_SELF_SERVICE&EOPP.SCLabel=Campus%20Finances&EOPP.SCFName=HCCC_FINANCES&EOPP.SCSecondary=true
        &EOPP.SCPTfname=HCCC_FINANCES&FolderPath=PORTAL_ROOT_OBJECT.CO_EMPLOYEE_SELF_SERVICE.
        HCCC_FINANCES.N_SSF_ACNT_SUMMARY_GBL&IsFolder=false&
        PortalActualURL=https%3a%2f%2fcms.mmu.edu.my%2fpsc%2fcsprd%2fEMPLOYEE%2fHRMS%2fc%2fSA_LEARNER_SERVICES.N_SSF_ACNT_SUMMARY.GBL&
        PortalContentURL=https%3a%2f%2fcms.mmu.edu.my%2fpsc%2fcsprd%2fEMPLOYEE%2fHRMS%2fc%2fSA_LEARNER_SERVICES.N_SSF_ACNT_SUMMARY.GBL&
        PortalContentProvider=HRMS&PortalCRefLabel=Account%20Enquiry&PortalRegistryName=EMPLOYEE&
        PortalServletURI=https%3a%2f%2fcms.mmu.edu.my%2fpsp%2fcsprd%2f&PortalURI=https%3a%2f%2fcms.mmu.edu.my%2fpsc%2fcsprd%2f&
        PortalHostNode=HRMS&NoCrumbs=yes&PortalKeyStruct=yes")
      # if(!page.parser.xpath('//*[@id="SSF_SS_DERIVED_SSF_AMOUNT_TOTAL2"]').blank?)
      #   amount_due = page.parser.xpath('//*[@id="SSF_SS_DERIVED_SSF_AMOUNT_TOTAL2"]').text
      if(!page.parser.xpath('//*[@id="N_CUST_SS_DRVD_ACCOUNT_BALANCE"]').blank?)
        amount_due = page.parser.xpath('//*[@id="N_CUST_SS_DRVD_ACCOUNT_BALANCE"]').text
        response[:amount_due] = amount_due
      end
      page = @agent.get("https://cms.mmu.edu.my/psc/csprd/EMPLOYEE/HRMS/c/N_MANAGE_EXAMS.N_SS_EXAM_TIMETBL.GBL?
        PORTALPARAM_PTCNAV=N_SS_EXAM_TIMETBL_GBL&EOPP.SCNode=HRMS&EOPP.SCPortal=EMPLOYEE&EOPP.SCName
        =CO_EMPLOYEE_SELF_SERVICE&EOPP.SCLabel=Self%20Service&EOPP.SCPTfname=CO_EMPLOYEE_SELF_SERVICE&
        FolderPath=PORTAL_ROOT_OBJECT.CO_EMPLOYEE_SELF_SERVICE.N_SS_EXAM_TIMETBL_GBL&IsFolder=false&
        PortalActualURL=https%3a%2f%2fcms.mmu.edu.my%2fpsc%2fcsprd%2fEMPLOYEE%2fHRMS%2fc%2fN_MANAGE_EXAMS.
        N_SS_EXAM_TIMETBL.GBL&PortalContentURL=https%3a%2f%2fcms.mmu.edu.my%2fpsc%2fcsprd%2fEMPLOYEE%2fHRMS%
        2fc%2fN_MANAGE_EXAMS.N_SS_EXAM_TIMETBL.GBL&PortalContentProvider=HRMS&PortalCRefLabel=My%20Exam%
        20Timetable&PortalRegistryName=EMPLOYEE&PortalServletURI=https%3a%2f%2fcms.mmu.edu.my%2fpsp%2fcsprd%
        2f&PortalURI=https%3a%2f%2fcms.mmu.edu.my%2fpsc%2fcsprd%2f&PortalHostNode=HRMS&NoCrumbs=yes&
        PortalKeyStruct=yes")
      exam_table = page.parser.xpath('//*[@id="N_SS_EXAM_TTBL$scroll$0"]/tr[2]/td/table')
      exam_table_fields = exam_table.xpath('tr[1]').text.split("\n").reject!(&:blank?)
      exam_timetable = []
      current_row = 2
      while(!exam_table.xpath("tr[#{current_row}]").empty? ) do
        exam_row = exam_table.xpath("tr[#{current_row}]").text.split("\n").reject!(&:blank?)[1..-1]
        exam_timetable << Hash[exam_table_fields.zip(exam_row)]
        current_row = current_row + 1
      end
      response[:exam_timetable] = exam_timetable

      @agent.get("https://cms.mmu.edu.my/psp/csprd/EMPLOYEE/HRMS/?cmd=logout")

      render json: JSON.pretty_generate(response.as_json)
    else
      render json: {error: "Incorrect CAMSYS username or password", status: 400}, status: 400
    end
  end

  def login_camsys
    @agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    page = @agent.get("https://cms.mmu.edu.my/psp/csprd/?&cmd=login&languageCd=ENG")
    form = page.form
    form.userid = params[:student_id]
    form.pwd = params[:camsys_password]
    page = @agent.submit(form)
    if page.parser.xpath('//*[@id="login_error"]').empty?
      page = @agent.get("https://cms.mmu.edu.my/psc/csprd/EMPLOYEE/HRMS/c/N_SR_STUDENT_RECORDS.N_SR_SS_ATTEND_PCT.GBL?
        PORTALPARAM_PTCNAV=HC_SSS_attendance_PERCENT_GBL&EOPP.SCNode=HRMS&EOPP.SCPortal=EMPLOYEE&EOPP.SCName=
        CO_EMPLOYEE_SELF_SERVICE&EOPP.SCLabel=Self%20Service&EOPP.SCPTfname=CO_EMPLOYEE_SELF_SERVICE&FolderPath=
        PORTAL_ROOT_OBJECT.CO_EMPLOYEE_SELF_SERVICE.HCCC_ACADEMIC_RECORDS.HC_SSS_attendance_PERCENT_GBL&IsFolder=
        false&PortalActualURL=https%3a%2f%2fcms.mmu.edu.my%2fpsc%2fcsprd%2fEMPLOYEE%2fHRMS%2fc%2fN_SR_STUDENT_RECORDS.
        _SR_SS_ATTEND_PCT.GBL&PortalContentURL=https%3a%2f%2fcms.mmu.edu.my%2fpsc%2fcsprd%2fEMPLOYEE%2fHRMS%2fc%
        2fN_SR_STUDENT_RECORDS.N_SR_SS_ATTEND_PCT.GBL&PortalContentProvider=HRMS&PortalCRefLabel=attendance%
        20Percentage%20by%20class&PortalRegistryName=EMPLOYEE&PortalServletURI=https%3a%2f%2fcms.mmu.edu.my
        %2fpsp%2fcsprd%2f&PortalURI=https%3a%2f%2fcms.mmu.edu.my%2fpsc%2fcsprd%2f&PortalHostNode=HRMS&NoCrumbs=yes
        &PortalKeyStruct=yes")
      subjects_attendance = []
      attendance_table = page.parser.xpath('//*[@id="N_STN_ENRL_SSVW$scroll$0"]')
      attendance_table_fields = attendance_table.xpath("tr[2]").text.split("\n").reject!(&:empty?)
      current_row = 3
      while(!attendance_table.xpath("tr[#{current_row}]").empty? ) do
        subject_row = attendance_table.xpath("tr[#{current_row}]").text.split("\n").reject!(&:empty?)
        subject_is_not_barred = attendance_table.xpath("tr[#{current_row}]/td[6]/div/input").attr('value').value == "Y"? "false" : "true"
        subject_row.insert(5, subject_is_not_barred)
        subjects_attendance << Hash[attendance_table_fields.zip(subject_row)]
        current_row = current_row + 1
      end
      @agent.get("https://cms.mmu.edu.my/psp/csprd/EMPLOYEE/HRMS/?cmd=logout")
      render json: JSON.pretty_generate(subjects_attendance.as_json)
    else
      render json: {error: "Incorrect CAMSYS username or password", status: 400}, status: 400
    end
  end

  def simple_timetable
    @agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    page = @agent.get("https://cms.mmu.edu.my")
    form = page.form
    form.userid = params[:student_id]
    form.pwd = params[:password]
    page = @agent.submit(form)
    if page.parser.xpath('//*[@id="login_error"]').empty?
      page = @agent.get("https://cms.mmu.edu.my/psc/csprd/EMPLOYEE/HRMS/c/SA_LEARNER_SERVICES.SSR_SSENRL_SCHD_W.GBL?Page=SSR_SS_WEEK&Action=A&ACAD_CAREER=UGRD&AS_OF_DATE=2015-06-22&EMPLID=1141125087&INSTITUTION=MMU01&STRM=1510&TargetFrameName=None")
      table = page.parser.xpath('//*[@id="WEEKLY_SCHED_HTMLAREA"]')
      render json: {timetable: table.to_s}
    else
      render json: {error: "Incorrect CAMSYS username or password", status: 400}, status: 400
    end
  end

  def timetable
    @agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    page = @agent.get("https://cms.mmu.edu.my")
    form = page.form
    form.userid = params[:student_id] ||= ENV['STUDENT_ID']
    form.pwd = params[:password] ||= ENV['CAMSYS_PASSWORD']
    page = @agent.submit(form)
    subjects = []
    if page.parser.xpath('//*[@id="login_error"]').empty?
      page = @agent.get("https://cms.mmu.edu.my/psc/csprd/EMPLOYEE/HRMS/c/SA_LEARNER_SERVICES.SSR_SSENRL_LIST.GBL?PORTALPARAM_PTCNAV=HC_SSR_SSENRL_LIST&amp;EOPP.SCNode=HRMS&amp;EOPP.SCPortal=EMPLOYEE&amp;EOPP.SCName=CO_EMPLOYEE_SELF_SERVICE&amp;EOPP.SCLabel=Self%20Service&amp;EOPP.SCPTfname=CO_EMPLOYEE_SELF_SERVICE&amp;FolderPath=PORTAL_ROOT_OBJECT.CO_EMPLOYEE_SELF_SERVICE.HCCC_ENROLLMENT.HC_SSR_SSENRL_LIST&amp;IsFolder=false&amp;PortalActualURL=https%3a%2f%2fcms.mmu.edu.my%2fpsc%2fcsprd%2fEMPLOYEE%2fHRMS%2fc%2fSA_LEARNER_SERVICES.SSR_SSENRL_LIST.GBL&amp;PortalContentURL=https%3a%2f%2fcms.mmu.edu.my%2fpsc%2fcsprd%2fEMPLOYEE%2fHRMS%2fc%2fSA_LEARNER_SERVICES.SSR_SSENRL_LIST.GBL&amp;PortalContentProvider=HRMS&amp;PortalCRefLabel=My%20Class%20Schedule&amp;PortalRegistryName=EMPLOYEE&amp;PortalServletURI=https%3a%2f%2fcms.mmu.edu.my%2fpsp%2fcsprd%2f&amp;PortalURI=https%3a%2f%2fcms.mmu.edu.my%2fpsc%2fcsprd%2f&amp;PortalHostNode=HRMS&amp;NoCrumbs=yes&amp;PortalKeyStruct=yes")
      table = page.parser.xpath('//*[@id="ACE_STDNT_ENRL_SSV2$0"]')
      a = 2
      while !table.xpath("tr[#{a}]").empty? do
        filter = table.xpath("tr[#{a}]/td[2]/div/table")
        subject = Subject.new
        subject.name = filter.xpath('tr[1]').text
        status_temp = filter.xpath("tr[2]/td[1]/table/tr[2]").text.split("\n")
        status_temp.delete("")
        subject.status = status_temp[4]
        i = 2
        subject_class = subject.subject_classes.build
        holder = filter.xpath('tr[2]/td[1]/table/tr[3]/td/div/table')
        while !holder.xpath("tr[#{i}]").empty? do
          temp = holder.xpath("tr[#{i}]")
          test = temp.xpath('td[1]').text.split("\n")
          unless test.join.blank?
             unless subject_class.class_number.nil?
               subject_class = subject.subject_classes.build
             end
            subject_class.class_number = temp.xpath('td[1]').text.delete("\n")
            subject_class.section = temp.xpath('td[2]').text.delete("\n")
            subject_class.component = temp.xpath('td[3]').text.delete("\n")
          end
          timeslot = subject_class.timeslots.build
          timeslot.day = temp.xpath('td[4]').text.delete("\n").split(" ")[0]
          timeslot.start_time = temp.xpath('td[4]').text.delete("\n").slice!(3,999).split(" - ")[0]
          timeslot.end_time = temp.xpath('td[4]').text.delete("\n").slice!(3,999).split(" - ")[1]
          timeslot.venue = temp.xpath('td[5]').text.delete("\n")
          i = i + 1
        end
        a = a + 2
        subjects << subject
      end
      subjects_json = subjects.as_json( :include => { :subject_classes => {
                                                       :include => {:timeslots => { :except => [:id, :subject_class_id] } },
                                                        :except => [:id] } },
                                                        :except => [:id, :subject_class_id])
      render :json => JSON.pretty_generate(subjects_json)
    else
      message = Hash.new
      message[:error] = "Incorrect username or password"
      message[:status] = "400"
      render json: message
    end
  end
  def login_mmls
    page = @agent.get("https://mmls.mmu.edu.my")
    print "Page acquired \n"
    form = page.form
    form.stud_id = params[:student_id]
    form.stud_pswrd = params[:mmls_password]
    token = form._token
    page = @agent.submit(form)
    details_array = page.parser.xpath('/html/body/div[1]/div[3]/div/div/div/div[2]/div[2]/div[2]').text.delete("\r\t()").split("\n")
    details = Hash.new
    details[:name] = details_array[1]
    details[:faculty] = details_array[3]
    subject_links = page.links_with(:text => /[A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9] . [A-Z][A-Z]/)
    subjects = []
    subject_links.each do |link|
      subject = Hash.new
      subject[:uri] = link.href
      subject[:name] = link.text
      subjects << subject
    end

    laravel_cookie = @agent.cookie_jar.first.value
    unless page.parser.xpath('//*[@id="alert"]').empty?
     render json: {message: "Incorrect MMLS username or password", status: 400}, status:400
    else
      render json: {message: "Successful Login", profile: details, cookie: laravel_cookie, subjects: subjects, token: token,status: 100}
    end
  end
  def get_token
    page = @agent.get("https://mmls.mmu.edu.my")
    form = page.form
    render json: {token: form._token}
  end

  def bulletin
    @bulletins = Bulletin.order(posted_on: :desc, url: :desc).limit(20)
  end

  def bulletin_api
    headers['Access-Control-Allow-Origin'] = "*"
    @bulletins = Bulletin.order(posted_on: :desc, url: :desc).limit(20)
    if !params[:last_sync].blank?
      last_sync = Time.parse(params[:last_sync])
      render json: @bulletins.where( "posted_on >= ?", last_sync.to_date).as_json( methods: :posted_date,except: [:posted_on,:created_at, :updated_at, :expired_on, :id])
    else
      render json: @bulletins.as_json( methods: :posted_date, except: [:posted_on,:created_at, :updated_at, :expired_on, :id])
    end
  end

  def mmls_refresh_subject
    url = params[:subject_url]
    name = "laravel_session"
    value = params[:cookie]
    if !params[:last_sync].blank?
      last_sync = Time.parse(params[:last_sync])
    end
    domain = "mmls.mmu.edu.my"
    cookie = Mechanize::Cookie.new :domain => domain, :name => name, :value => value, :path => '/', :expires => (Date.today + 1).to_s
    @agent.cookie_jar.add(cookie)
    @agent.redirect_ok = false


    base_uri = 'https://mmu-hub.firebaseio.com/'
    firebase = Firebase::Client.new(base_uri)

    page = @agent.get(url)
    if page.code != "302"
      print "Page acquired, processing .. + \n"
      original = page.parser.xpath('/html/body/div[1]/div[3]/div/div/div/div[1]')
      subject_name = page.parser.xpath("/html/body/div[1]/div[3]/div/div/div/div[1]/div[1]/h3/div").text.delete("\n\t")
      subject = Subject.new
      subject.name = subject_name
      weeks_firebase = []
      week_number = 1
      while !page.parser.xpath("//*[@id='accordion']/div[#{week_number}]/div[1]/h3/a").empty? do
        week = subject.weeks.build
        week.title = page.parser.xpath("//*[@id='accordion']/div[#{week_number}]/div[1]/h3/a").text.delete("\r").delete("\n").delete("\t").split(" - ")[0]
        announcement_number = 1
        announcement_generic_path = page.parser.xpath("//*[@id='accordion']/div[#{week_number}]/div[2]/div/div/div[1]")

        announcements_firebase = []
        while !announcement_generic_path.xpath("div[#{announcement_number}]/font").empty? do
          posted_date = announcement_generic_path.xpath("div[#{announcement_number}]/div[1]/i[1]").text.delete("\r").delete("\n").delete("\t").split("               ").last
          valid = false
          if(!params[:last_sync].blank?)
            if(Time.parse(posted_date).to_date >= last_sync.to_date)
              valid = true
            end
          else
            valid = true
          end

          announcement_firebase = {}

          if(valid)
            announcement = week.announcements.build
            announcement.title = announcement_generic_path.xpath("div[#{announcement_number}]/font").inner_text.delete("\r").delete("\t")
            contents = announcement_generic_path.xpath("div[#{announcement_number}]").children[7..-1]
            sanitized_contents = Sanitize.clean(contents, :remove_contents => ['script', 'style'])
            announcement.contents = sanitized_contents.delete("\r\t")
            announcement.author = announcement_generic_path.xpath("div[#{announcement_number}]/div[1]/i[1]").text.delete("\r\n\t\t\t\t\t;").split("  ").first[3..-1]
            announcement.posted_date = posted_date

            annoucement_firebase = { title:announcement.title,
             contents: announcement.contents, author:announcement.author,
             posted_date:announcement.posted_date }

            if !announcement_generic_path.xpath("div[#{announcement_number}]").at('form').nil?
              print("FILES EXISTS !!!")
              form_nok = announcement_generic_path.xpath("div[#{announcement_number}]").at('form')
              form = Mechanize::Form.new form_nok, @agent, page
              file_details_hash =  Hash[form.keys.zip(form.values)]
              file = announcement.subject_files.build
              file.file_name = file_details_hash["file_name"]
              file.token = file_details_hash["_token"]
              file.content_id = file_details_hash["content_id"]
              file.content_type = file_details_hash["content_type"]
              file.file_path = file_details_hash["file_path"]
            end
          end
          announcements_firebase.push(annoucement_firebase)
          announcement_number = announcement_number + 1
        end
        weeks_firebase.push({ title: week.title, announcements: announcements_firebase})
        week_number = week_number + 1
       end

       subject_files_firebase = []
       download_forms = page.forms_with(:action => 'https://mmls.mmu.edu.my/form-download-content').uniq{ |x| x.content_id }
       download_forms.each do |form|
         file_details_hash =  Hash[form.keys.zip(form.values)]
         file = subject.subject_files.build
         file.file_name = file_details_hash["file_name"]
         file.token = file_details_hash["_token"]
         file.content_id = file_details_hash["content_id"]
         file.content_type = file_details_hash["content_type"]
         file.file_path = file_details_hash["file_path"]
         subject_files_firebase.push({file_name: file.file_name, token: file.token,
          content_id:file.content_id, content_type: file.content_type, file_path: file.file_path})
       end


      response = firebase.set("subjects/PWC1010", { name: subject.name, weeks: weeks_firebase, subject_files: subject_files_firebase })
       render :json => subject.as_json(
          :include => [{ :weeks => {
          :include => {:announcements => {:include => :subject_files} }}}, :subject_files])
     else
       render json: {message: "Cookie Expired", status: 400}, status: 400
     end
  end

  private
    def set_agent
      @agent = Mechanize.new
      # @agent.redirect_ok = false
      @agent.keep_alive = true
      @agent.agent.http.retry_change_requests = true
    end 
    def timetable_params
      timetable_params.allow("student_id", "password")
    end
end
