class AdminGroups < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedUser
  include SharedActiveTab
  include Select2Helper

  When 'I visit admin group page' do
    visit admin_group_path(current_group)
  end

  When 'I click new group link' do
    click_link "New Group"
  end

  And 'I have group with projects' do
    @group   = create(:group)
    @project = create(:project, group: @group)
    @event   = create(:closed_issue_event, project: @project)

    @project.team << [current_user, :master]
  end

  And 'submit form with new group info' do
    fill_in 'group_name', with: 'gitlab'
    fill_in 'group_description', with: 'Group description'
    click_button "Create group"
  end

  Then 'I should see newly created group' do
    page.should have_content "Group: gitlab"
    page.should have_content "Group description"
  end

  Then 'I should be redirected to group page' do
    current_path.should == admin_group_path(Group.last)
  end

  When 'I select user "John Doe" from user list as "Reporter"' do
    user = User.find_by(name: "John Doe")
    select2(user.id, from: "#user_ids", multiple: true)
    within "#new_team_member" do
      select "Reporter", from: "group_access"
    end
    click_button "Add users into group"
  end

  Then 'I should see "John Doe" in team list in every project as "Reporter"' do
    within ".group-users-list" do
      page.should have_content "John Doe"
      page.should have_content "Reporter"
    end
  end

  step 'I should be all groups' do
    Group.all.each do |group|
      page.should have_content group.name
    end
  end

  step 'group has shared projects' do
    share_link = shared_project.project_group_links.new(group_access: Gitlab::Access::MASTER)
    share_link.group_id = current_group.id
    share_link.save!
  end

  step 'I visit group page' do
    visit admin_group_path(current_group)
  end

  step 'I should see project shared with group' do
    page.should have_content(shared_project.name_with_namespace)
    page.should have_content "Projects shared with"
  end

  protected

  def current_group
    @group ||= Group.first
  end

  def shared_project
    @shared_project ||= create(:empty_project)
  end
end
