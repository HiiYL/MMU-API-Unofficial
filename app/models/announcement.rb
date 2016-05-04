class Announcement < ActiveRecord::Base
  belongs_to :week
  has_many :subject_files
end
public
  def login_mmls_headless(student_id, mmls_password)
  	set_agent()
    page = @agent.get("https://mmls.mmu.edu.my")
    print "Page acquired \n"
    form = page.form
    form.stud_id = student_id
    form.stud_pswrd = mmls_password
    token = form._token
    page = @agent.submit(form)
    if page.parser.xpath('//*[@id="alert"]').empty?
      laravel_cookie = @agent.cookie_jar.first.value
      return laravel_cookie
    end
  end

  def refresh_mmls()
    base_uri = 'https://mmu-hub.firebaseio.com/'
    firebase = Firebase::Client.new(base_uri)
    response = firebase.get("subjects2")
    response.body.each do |key, value|
      subject_url = key
      value["students"].each do |key,value|
        student_id = value["student_id"]
        mmls_password = value["password"]
        puts student_id + " " + mmls_password
        auth_key = login_mmls_headless(student_id, mmls_password)
        success = mmls_refresh_subject_firebase_no_weeks(subject_url, student_id,mmls_password,auth_key)
        if success
          break
        end
      end
    end
  end

  def mmls_refresh_subject_firebase_no_weeks(subject_url, student_id, mmls_password,auth_key)
    set_agent()
    value = auth_key
    url = "https://mmls.mmu.edu.my/" + subject_url
    name = "laravel_session"
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
      # subject_campus = ""

      weeks_firebase = Hash.new
      announcements_firebase = []
      for week in page.parser.xpath("//*[@id='accordion']/div")
        # week_firebase = Hash.new
        title = week.xpath("div[1]/h3/a").text().strip()
        if !title.split("  (")[0].nil?
          week_number = title.split("  (")[0].delete("^0-9").to_i
        else
          week_number = -1
        end
        for announcement in week.xpath("div[2]/div/div/div[1]/div[1]")
          announcement_firebase = Hash.new
          announcement_firebase["contents"] = announcement.to_s
          announcement_firebase["title"] = announcement.xpath("font").text().strip()
          announcement_firebase["week_number"] = week_number
          # announcement_firebase["week_title"] = week_number
          announcement_firebase["author"] = announcement.xpath("div[1]/i[1]").text.strip().split("  ").first[3..-1]
          announcement_firebase["posted_date"] = announcement.xpath("div[1]/i[1]").text().delete("\r\n\t;").split(" ").last.to_time.to_i
          announcement_firebase["priority"] = -announcement_firebase["posted_date"]

          unless announcement.at('form').nil?
            file = Hash.new
            form_nok = announcement.at('form')
            form = Mechanize::Form.new form_nok, @agent, page
            file_details_hash =  Hash[form.keys.zip(form.values)]
            file["file_name"] = file_details_hash["file_name"]
            file["token"] = file_details_hash["_token"]
            file["content_id"] = file_details_hash["content_id"]
            file["content_type"] = file_details_hash["content_type"]
            file["file_path"] = file_details_hash["file_path"]
            announcement_firebase["file"] = file
          end
          announcements_firebase.push(announcement_firebase)
        end
      end
      subject_files_firebase = []
      download_forms = page.forms_with(:action => 'https://mmls.mmu.edu.my/form-download-content').uniq{ |x| x.content_id }
      download_forms.each do |form|
        file_details_hash =  Hash[form.keys.zip(form.values)]
        file = Hash.new
        file["file_name"] = file_details_hash["file_name"]
        file["token"] = file_details_hash["_token"]
        file["content_id"] = file_details_hash["content_id"]
        file["content_type"] = file_details_hash["content_type"]
        file["file_path"] = file_details_hash["file_path"]

        subject_files_firebase.push(file)
      end

      response = firebase.update("subjects3/" + subject_url, { name: subject.name, announcements: announcements_firebase, subject_files: subject_files_firebase})

      #   # week_firebase["title"] = title
      #   # weeks_firebase[title] = week_firebase
      #   puts week_firebase
      # end
      #   # weeks_firebase[title] = week_firebase

      # # for week in page.parser.xpath('//*[starts-with(@id, "home")]')

      # for week in page.parser.xpath("//*[@id='accordion']/div/div[1]/h3/a")
      #   week.title = page.parser.xpath("//*[@id='accordion']/div[#{week_number}]/div[1]/h3/a").text.delete("\r").delete("\n").delete("\t").split(" - ")[0]


      # while !page.parser.xpath("//*[@id='accordion']/div[#{week_number}]/div[1]/h3/a").empty? do
      #   week = subject.weeks.build
      #   week.title = page.parser.xpath("//*[@id='accordion']/div[#{week_number}]/div[1]/h3/a").text.delete("\r").delete("\n").delete("\t").split(" - ")[0]
      #   announcement_number = 1
      #   announcement_generic_path = page.parser.xpath("//*[@id='accordion']/div[#{week_number}]/div[2]/div/div/div[1]")

      #   announcements_firebase = []
      #   while !announcement_generic_path.xpath("div[#{announcement_number}]/font").empty? do
      #     posted_date = announcement_generic_path.xpath("div[#{announcement_number}]/div[1]/i[1]").text.delete("\r").delete("\n").delete("\t").split("               ").last
      #     valid = true
      #     announcement_firebase = {}

      #     if(valid)
      #       announcement = week.announcements.build
      #     else
      #       announcement = Announcement.new
      #     end
          # announcement.title = announcement_generic_path.xpath("div[#{announcement_number}]/font").inner_text.delete("\r").delete("\t")
          # announcement.contents = announcement_generic_path.xpath("div[#{announcement_number}]").children[7..-1]
          # # sanitized_contents = Sanitize.clean(contents, :remove_contents => ['script', 'style'])
          # # announcement.contents = sanitized_contents.delete("\r\t")
          # announcement.author = announcement_generic_path.xpath("div[#{announcement_number}]/div[1]/i[1]").text.delete("\r\n\t\t\t\t\t;").split("  ").first[3..-1]
          # announcement.posted_date = posted_date

 
      #     announcements_file_firebase = {}
      #     if !announcement_generic_path.xpath("div[#{announcement_number}]").at('form').nil?
      #       print("FILES EXISTS !!!")
      #       form_nok = announcement_generic_path.xpath("div[#{announcement_number}]").at('form')
      #       form = Mechanize::Form.new form_nok, @agent, page
      #       file_details_hash =  Hash[form.keys.zip(form.values)]
      #       if(valid)
      #         file = announcement.subject_files.build
      #       else
      #         file = SubjectFile.new
      #       end
      #       file.file_name = file_details_hash["file_name"]
      #       file.token = file_details_hash["_token"]
      #       file.content_id = file_details_hash["content_id"]
      #       file.content_type = file_details_hash["content_type"]
      #       file.file_path = file_details_hash["file_path"]
      #       # if subject_campus == ""
      #       #   subject_campus = file.file_path.split("/")[0]
      #       # end
      #       announcements_file_firebase = { file_name: file.file_name,
      #        token: file.token, content_id: file.content_id,
      #        content_type: file.content_type, file_path: file.file_path
      #       }
      #       annoucement_firebase = { title:announcement.title,
      #         contents: announcement.contents, author:announcement.author,
      #         posted_date:announcement.posted_date.to_time.to_i, file: announcements_file_firebase }
      #     else
      #     annoucement_firebase = { title:announcement.title,
      #         contents: announcement.contents, author:announcement.author,
      #         posted_date:announcement.posted_date.to_time.to_i}
      #     end
      #     announcements_firebase.push(annoucement_firebase)
      #     announcement_number = announcement_number + 1
      #   end
      #   if announcements_firebase.length > 0
      #     filtered_weekname = week.title.split("  (")[0].delete("^0-9")
      #     weeks_firebase[filtered_weekname] =  { title: week.title, announcements: announcements_firebase}
      #   end
      #   week_number = week_number + 1
      #  end

      #  subject_files_firebase = []
      #  download_forms = page.forms_with(:action => 'https://mmls.mmu.edu.my/form-download-content').uniq{ |x| x.content_id }
      #  download_forms.each do |form|
      #    file_details_hash =  Hash[form.keys.zip(form.values)]
      #    file = subject.subject_files.build
      #    file.file_name = file_details_hash["file_name"]
      #    file.token = file_details_hash["_token"]
      #    file.content_id = file_details_hash["content_id"]
      #    file.content_type = file_details_hash["content_type"]
      #    file.file_path = file_details_hash["file_path"]
      #    # if subject_campus == ""
      #    #  subject_campus = file.file_path.split("/")[0]
      #    # end
      #    subject_files_firebase.push({file_name: file.file_name, token: file.token,
      #     content_id:file.content_id, content_type: file.content_type, file_path: file.file_path})
      #  end

      # # if subject_campus != ""
      # #   unique_name = [subject.name.split(" - ")[0],subject_campus].join('_')
      # # else
      # #   unique_name = subject.name.split(" - ")[0]
      # # end
      # response = firebase.update("subjects2/" + subject_url, { name: subject.name, weeks: weeks_firebase, subject_files: subject_files_firebase })
      return true
     else
       return false
     end

  end

  # def mmls_refresh_subject_firebase(subject_url, student_id, mmls_password,auth_key)
  #   value = auth_key
  #   url = "https://mmls.mmu.edu.my/" + subject_url
  #   name = "laravel_session"
  #   domain = "mmls.mmu.edu.my"
  #   cookie = Mechanize::Cookie.new :domain => domain, :name => name, :value => value, :path => '/', :expires => (Date.today + 1).to_s
  #   @agent.cookie_jar.add(cookie)
  #   @agent.redirect_ok = false


  #   base_uri = 'https://mmu-hub.firebaseio.com/'
  #   firebase = Firebase::Client.new(base_uri)

  #   page = @agent.get(url)
  #   if page.code != "302"
  #     print "Page acquired, processing .. + \n"
  #     original = page.parser.xpath('/html/body/div[1]/div[3]/div/div/div/div[1]')
  #     subject_name = page.parser.xpath("/html/body/div[1]/div[3]/div/div/div/div[1]/div[1]/h3/div").text.delete("\n\t")
  #     subject = Subject.new
  #     subject.name = subject_name
  #     subject_campus = ""
  #     weeks_firebase = Hash.new
  #     week_number = 1
  #     while !page.parser.xpath("//*[@id='accordion']/div[#{week_number}]/div[1]/h3/a").empty? do
  #       week = subject.weeks.build
  #       week.title = page.parser.xpath("//*[@id='accordion']/div[#{week_number}]/div[1]/h3/a").text.delete("\r").delete("\n").delete("\t").split(" - ")[0]
  #       announcement_number = 1
  #       announcement_generic_path = page.parser.xpath("//*[@id='accordion']/div[#{week_number}]/div[2]/div/div/div[1]")

  #       announcements_firebase = []
  #       while !announcement_generic_path.xpath("div[#{announcement_number}]/font").empty? do
  #         posted_date = announcement_generic_path.xpath("div[#{announcement_number}]/div[1]/i[1]").text.delete("\r").delete("\n").delete("\t").split("               ").last
  #         valid = true
  #         announcement_firebase = {}

  #         if(valid)
  #           announcement = week.announcements.build
  #         else
  #           announcement = Announcement.new
  #         end
  #         announcement.title = announcement_generic_path.xpath("div[#{announcement_number}]/font").inner_text.delete("\r").delete("\t")
  #         announcement.contents = announcement_generic_path.xpath("div[#{announcement_number}]").children[7..-1]
  #         # sanitized_contents = Sanitize.clean(contents, :remove_contents => ['script', 'style'])
  #         # announcement.contents = sanitized_contents.delete("\r\t")
  #         announcement.author = announcement_generic_path.xpath("div[#{announcement_number}]/div[1]/i[1]").text.delete("\r\n\t\t\t\t\t;").split("  ").first[3..-1]
  #         announcement.posted_date = posted_date

 
  #         announcements_file_firebase = {}
  #         if !announcement_generic_path.xpath("div[#{announcement_number}]").at('form').nil?
  #           print("FILES EXISTS !!!")
  #           form_nok = announcement_generic_path.xpath("div[#{announcement_number}]").at('form')
  #           form = Mechanize::Form.new form_nok, @agent, page
  #           file_details_hash =  Hash[form.keys.zip(form.values)]
  #           if(valid)
  #             file = announcement.subject_files.build
  #           else
  #             file = SubjectFile.new
  #           end
  #           file.file_name = file_details_hash["file_name"]
  #           file.token = file_details_hash["_token"]
  #           file.content_id = file_details_hash["content_id"]
  #           file.content_type = file_details_hash["content_type"]
  #           file.file_path = file_details_hash["file_path"]
  #           if subject_campus == ""
  #             subject_campus = file.file_path.split("/")[0]
  #           end
  #           announcements_file_firebase = { file_name: file.file_name,
  #            token: file.token, content_id: file.content_id,
  #            content_type: file.content_type, file_path: file.file_path
  #           }
  #           annoucement_firebase = { title:announcement.title,
  #             contents: announcement.contents, author:announcement.author,
  #             posted_date:announcement.posted_date.to_time.to_i, file: announcements_file_firebase }
  #         else
  #         annoucement_firebase = { title:announcement.title,
  #             contents: announcement.contents, author:announcement.author,
  #             posted_date:announcement.posted_date.to_time.to_i}
  #         end
  #         announcements_firebase.push(annoucement_firebase)
  #         announcement_number = announcement_number + 1
  #       end
  #       if announcements_firebase.length > 0
  #         filtered_weekname = week.title.split("  (")[0].delete("^0-9")
  #         weeks_firebase[filtered_weekname] =  { title: week.title, announcements: announcements_firebase}
  #       end
  #       week_number = week_number + 1
  #      end

  #      subject_files_firebase = []
  #      download_forms = page.forms_with(:action => 'https://mmls.mmu.edu.my/form-download-content').uniq{ |x| x.content_id }
  #      download_forms.each do |form|
  #        file_details_hash =  Hash[form.keys.zip(form.values)]
  #        file = subject.subject_files.build
  #        file.file_name = file_details_hash["file_name"]
  #        file.token = file_details_hash["_token"]
  #        file.content_id = file_details_hash["content_id"]
  #        file.content_type = file_details_hash["content_type"]
  #        file.file_path = file_details_hash["file_path"]
  #        if subject_campus == ""
  #         subject_campus = file.file_path.split("/")[0]
  #        end
  #        subject_files_firebase.push({file_name: file.file_name, token: file.token,
  #         content_id:file.content_id, content_type: file.content_type, file_path: file.file_path})
  #      end

  #     if subject_campus != ""
  #       unique_name = [subject.name.split(" - ")[0],subject_campus].join('_')
  #     else
  #       unique_name = subject.name.split(" - ")[0]
  #     end
  #     response = firebase.update("subjects2/" + subject_url, { name: subject.name, weeks: weeks_firebase, subject_files: subject_files_firebase })
  #     return true
  #      # render :json => subject.as_json(
  #      #    :include => [{ :weeks => {
  #      #    :include => {:announcements => {:include => :subject_files} }}}, :subject_files])
  #    else
  #      return false
  #      # render json: {message: "Cookie Expired", status: 400}, status: 400
  #    end
  # end

 def set_agent
    @agent = Mechanize.new
    # @agent.redirect_ok = false
    @agent.keep_alive = true
    @agent.agent.http.retry_change_requests = true
  end