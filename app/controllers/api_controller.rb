class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token

  def portal
    bulletins = []
    agent = Mechanize.new
    page = agent.get("https://online.mmu.edu.my/index.php")
    form = page.form
    form.form_loginUsername = params[:student_id]
    #form.form_loginUsername =  ENV['STUDENT_ID']
    form.form_loginPassword = params[:password]
    #form.form_loginPassword = ENV['PORTAL_PASSWORD']
    page = agent.submit(form)
    tab_number = 1
    bulletin_number = 1
    while !page.parser.xpath("//*[@id='tabs']/div[#{tab_number}]/div[#{bulletin_number}]").empty?
      bulletin = Hash.new
      bulletin[:title] = page.parser.xpath("//*[@id='tabs']/div[#{tab_number}]/div[#{bulletin_number}]/p/a[1]").text
      bulletin_details = page.parser.xpath("//*[@id='tabs']/div[#{tab_number}]/div[#{bulletin_number}]/div/div/text()").text.split("\r\n        ").delete_if(&:empty?)
      #remember to add android autolink
      bulletin[:posted_date] = bulletin_details[0].split(" ")[2..5].join(" ")
      bulletin[:expired_date] = bulletin_details[1].split(" : ")[1]
      bulletin[:author] = bulletin_details[2].split(" : ")[1].delete("\t")
      page.parser.xpath("//*[@id='tabs']/div[1]/div[2]/div/div/div")
      bulletin[:contents] = page.parser.xpath("//*[@id='tabs']/div[#{tab_number}]/div[#{bulletin_number}]/div/div/div").text.delete("\t").delete("\r")
      bulletins << bulletin
      bulletin_number = bulletin_number + 1
    end
    render :json => JSON.pretty_generate(bulletins.as_json)
  end

  def mmls
    print "HELLO?"
    agent = Mechanize.new
    page = agent.get("https://mmls.mmu.edu.my")
    form = page.form
    form.stud_id = params[:student_id] ||= ENV['STUDENT_ID']
    form.stud_pswrd = params[:password] ||= ENV['MMLS_PASSWORD']
    page = agent.submit(form)
    if page.parser.xpath('//*[@id="alert"]').empty?
      subject_links = page.links_with(:text => /[A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9] . [A-Z][A-Z][A-Z]/)
      subjects = []
      files = []
      subject_links.each do |link|
        unless (subject = Subject.find_by_name(link.text) and subject.weeks.exists?)
          page = agent.get(link.uri)
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
              announcement.contents = announcement_generic_path.xpath("div[#{announcement_number}]").children[7..-1].text.delete("\r\t")
              announcement.author = announcement_generic_path.xpath("div[#{announcement_number}]/div[1]/i[1]").text.delete("\r").delete("\n").delete("\t").split("  ;   ").first[3..-1]
              announcement.posted_date = announcement_generic_path.xpath("div[#{announcement_number}]/div[1]/i[1]").text.delete("\r").delete("\n").delete("\t").split("               ").last
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
          subject.save
        end
        subjects << subject
      end
      render :json => JSON.pretty_generate(subjects.as_json(
          :include => [{ :weeks => {
          :include => :announcements}}, :subject_files]))
    else
      message = Hash.new
      message[:error] = "Incorrect username or password"
      message[:status] = "400"
      render json: message
    end
  end

  def mmls_files
  end

  def refresh
    agent = Mechanize.new
    page = agent.get("https://mmls.mmu.edu.my")
    form = page.form
    token = form._token
    form.stud_id = params[:student_id]
    form.stud_pswrd = params[:password]
    agent.submit(form)
    laravel_cookie = agent.cookie_jar.jar["mmls.mmu.edu.my"]["/"]["laravel_session"].value
    unless page.parser.xpath('//*[@id="alert"]').empty?
      render json: {message: "Incorrect MMLS username or password", status: 400}, status:400
    else
      render json: {token: form._token, cookie: laravel_cookie}
    end

  end
  def timetable
  	agent = Mechanize.new
    agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    page = agent.get("https://cms.mmu.edu.my")
    form = page.form
    form.userid = params[:student_id] ||= ENV['STUDENT_ID']
    form.pwd = params[:password] ||= ENV['CAMSYS_PASSWORD']
    page = agent.submit(form)
    subjects = []
    if page.parser.xpath('//*[@id="login_error"]').empty?
      page = agent.get("https://cms.mmu.edu.my/psc/csprd/EMPLOYEE/HRMS/c/SA_LEARNER_SERVICES.SSR_SSENRL_LIST.GBL?PORTALPARAM_PTCNAV=HC_SSR_SSENRL_LIST&amp;EOPP.SCNode=HRMS&amp;EOPP.SCPortal=EMPLOYEE&amp;EOPP.SCName=CO_EMPLOYEE_SELF_SERVICE&amp;EOPP.SCLabel=Self%20Service&amp;EOPP.SCPTfname=CO_EMPLOYEE_SELF_SERVICE&amp;FolderPath=PORTAL_ROOT_OBJECT.CO_EMPLOYEE_SELF_SERVICE.HCCC_ENROLLMENT.HC_SSR_SSENRL_LIST&amp;IsFolder=false&amp;PortalActualURL=https%3a%2f%2fcms.mmu.edu.my%2fpsc%2fcsprd%2fEMPLOYEE%2fHRMS%2fc%2fSA_LEARNER_SERVICES.SSR_SSENRL_LIST.GBL&amp;PortalContentURL=https%3a%2f%2fcms.mmu.edu.my%2fpsc%2fcsprd%2fEMPLOYEE%2fHRMS%2fc%2fSA_LEARNER_SERVICES.SSR_SSENRL_LIST.GBL&amp;PortalContentProvider=HRMS&amp;PortalCRefLabel=My%20Class%20Schedule&amp;PortalRegistryName=EMPLOYEE&amp;PortalServletURI=https%3a%2f%2fcms.mmu.edu.my%2fpsp%2fcsprd%2f&amp;PortalURI=https%3a%2f%2fcms.mmu.edu.my%2fpsc%2fcsprd%2f&amp;PortalHostNode=HRMS&amp;NoCrumbs=yes&amp;PortalKeyStruct=yes")
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
        # :include => { :subjects => {
        #  :include => { :subject_classes => {
        #   :include => :timeslots, :except => [:id]} }, :except => [:id,:subject_class_id] }},
        #    :except => [:id]))
    else
      message = Hash.new
      message[:error] = "Incorrect username or password"
      message[:status] = "400"
      render json: message
    end
  end

  def personal_information
    agent = Mechanize.new
    page = agent.get("https://mmls.mmu.edu.my")
    form = page.form
    form.stud_id = params[:student_id] ||= ENV['STUDENT_ID']
    form.stud_pswrd = params[:password] ||= ENV['MMLS_PASSWORD']
    page = agent.submit(form)
  end
  def login_mmls
    agent = Mechanize.new
    page = agent.get("https://mmls.mmu.edu.my")
    form = page.form
    form.stud_id = params[:student_id]
    form.stud_pswrd = params[:mmls_password]
    token = form._token
    page = agent.submit(form)
    details_array = page.parser.xpath('/html/body/div[1]/div[3]/div/div/div/div[2]/div[2]/div[2]').text.delete("\r\t()").split("\n")
    details = Hash.new
    details[:name] = details_array[1]
    details[:faculty] = details_array[3]
    laravel_cookie = agent.cookie_jar.jar["mmls.mmu.edu.my"]["/"]["laravel_session"].value
    unless page.parser.xpath('//*[@id="alert"]').empty?
     render json: {message: "Incorrect MMLS username or password", status: 400}, status:400
    else
      render json: {message: "Successful Login", profile: details, cookie: laravel_cookie, token: token,status: 100}
    end
  end
  def get_token
    agent = Mechanize.new
    page = agent.get("https://mmls.mmu.edu.my")
    form = page.form
    render json: {token: form._token}
  end
  def mmls_refresh_cookie
    agent = Mechanize.new
    page = agent.get("https://mmls.mmu.edu.my")
    form = page.form
    form.stud_id = params[:student_id]
    form.stud_pswrd = params[:mmls_password]
    page = agent.submit(form)
    laravel_cookie = agent.cookie_jar.jar["mmls.mmu.edu.my"]["/"]["laravel_session"].value
    unless page.parser.xpath('//*[@id="alert"]').empty?
     render json: {message: "Incorrect MMLS username or password", status: 400}, status:400
    else
      render json: {message: "Successful Login", cookie: laravel_cookie,status: 100}
    end
  end
  def login_test
    agent = Mechanize.new
    agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    page = agent.get("https://cms.mmu.edu.my")
    form = page.form
    form.userid = params[:student_id]
    form.pwd = params[:camsys_password]
    page = agent.submit(form)
    unless page.parser.xpath('//*[@id="login_error"]').empty?
      render json: {message: "Incorrect CAMSYS username or password", status: 400}, status:400
      return
    end
    page = agent.get("https://mmls.mmu.edu.my")
    form = page.form
    form.stud_id = params[:student_id] ||= ENV['STUDENT_ID']
    form.stud_pswrd = params[:mmls_password] ||= ENV['MMLS_PASSWORD']
    page = agent.submit(form)
    details_array = page.parser.xpath('/html/body/div[1]/div[3]/div/div/div/div[2]/div[2]/div[2]').text.delete("\r\t()").split("\n")
    details = Hash.new
    details[:name] = details_array[1]
    details[:faculty] = details_array[3]
    unless page.parser.xpath('//*[@id="alert"]').empty?
      render json: {message: "Incorrect MMLS username or password", status: 400}, status:400
      return
    end
    render json: {message: "Successful Login", profile: details,status: 100}
  end

  def login_portal_test

  end

  def login_mmls_test
    agent = Mechanize.new
    page = agent.get("https://mmls.mmu.edu.my")
    form = page.form
    form.stud_id = params[:student_id] ||= ENV['STUDENT_ID']
    form.stud_pswrd = params[:password] ||= ENV['MMLS_PASSWORD']
    page = agent.submit(form)
    if page.parser.xpath('//*[@id="alert"]').empty?
      render json: {success: "Successful Login", status: 100}
    else
      render json: {error: "Incorrect CAMSYS username or password", status: 400}
    end

  end

  def login_camsys_test
    agent = Mechanize.new
    agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    page = agent.get("https://cms.mmu.edu.my")
    form = page.form
    form.userid = params[:student_id] ||= ENV['STUDENT_ID']
    form.pwd = params[:password] ||= ENV['CAMSYS_PASSWORD']
    page = agent.submit(form)
    subjects = []
    if page.parser.xpath('//*[@id="login_error"]').empty?
      render json: {success: "Successful CAMSYS Login", status: 100}
    else
      render json: {error: "Incorrect CAMSYS username or password", status: 400}
    end
  end

  def download_mmls
    agent = Mechanize.new
    page = agent.get("https://mmls.mmu.edu.my")
    form = page.form
    form.stud_id = ENV['STUDENT_ID']
    form.stud_pswrd = ENV['MMLS_PASSWORD']
    page = agent.submit(form)
    agent.pluggable_parser.default = Mechanize::Download
    subject_links = page.links_with(:text => /[A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9] . [A-Z][A-Z][A-Z]/)
    page = agent.get(subject_links[2].uri)
    form = page.form_with(:action => 'https://mmls.mmu.edu.my/form-download-content')
    send_data agent.submit(form), name: "Lec7.pdf"
  end
  private
   def timetable_params
      timetable_params.allow("student_id", "password")
   end
end
