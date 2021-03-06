# frozen_string_literal: true

require 'spec_helper'

describe 'Slack slash commands' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    project.add_maintainer(user)
    sign_in(user)
    visit edit_project_service_path(project, :slack_slash_commands)
  end

  it 'shows a token placeholder' do
    token_placeholder = find_field('service_token')['placeholder']

    expect(token_placeholder).to eq('XXxxXXxxXXxxXXxxXXxxXXxx')
  end

  it 'shows a help message' do
    expect(page).to have_content('This service allows users to perform common')
  end

  it 'redirects to the integrations page after saving but not activating', :js do
    fill_in 'service_token', with: 'token'
    find('input[name="service[active]"] + button').click
    click_on 'Save'

    expect(current_path).to eq(project_settings_integrations_path(project))
    expect(page).to have_content('Slack slash commands settings saved, but not activated.')
  end

  it 'redirects to the integrations page after activating', :js do
    fill_in 'service_token', with: 'token'
    click_on 'Save'

    expect(current_path).to eq(project_settings_integrations_path(project))
    expect(page).to have_content('Slack slash commands activated.')
  end

  it 'shows the correct trigger url' do
    value = find_field('url').value
    expect(value).to match("api/v4/projects/#{project.id}/services/slack_slash_commands/trigger")
  end
end
