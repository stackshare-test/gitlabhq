require 'rails_helper'

describe 'Issue Boards add issue modal', :feature, :js do
  include WaitForAjax
  include WaitForVueResource

  let(:project) { create(:empty_project, :public) }
  let(:board) { create(:board, project: project) }
  let(:user) { create(:user) }
  let!(:planning) { create(:label, project: project, name: 'Planning') }
  let!(:label) { create(:label, project: project) }
  let!(:list1) { create(:list, board: board, label: planning, position: 0) }
  let!(:issue) { create(:issue, project: project) }
  let!(:issue2) { create(:issue, project: project) }

  before do
    project.team << [user, :master]

    login_as(user)

    visit namespace_project_board_path(project.namespace, project, board)
    wait_for_vue_resource
  end

  context 'modal interaction' do
    it 'opens modal' do
      click_button('Add issues')

      expect(page).to have_selector('.add-issues-modal')
    end

    it 'closes modal' do
      click_button('Add issues')

      page.within('.add-issues-modal') do
        find('.close').click
      end

      expect(page).not_to have_selector('.add-issues-modal')
    end

    it 'closes modal if cancel button clicked' do
      click_button('Add issues')

      page.within('.add-issues-modal') do
        click_button 'Cancel'
      end

      expect(page).not_to have_selector('.add-issues-modal')
    end
  end

  context 'issues list' do
    before do
      click_button('Add issues')

      wait_for_vue_resource
    end

    it 'loads issues' do
      page.within('.add-issues-modal') do
        page.within('.nav-links') do
          expect(page).to have_content('2')
        end

        expect(page).to have_selector('.card', count: 2)
      end
    end

    it 'shows selected issues' do
      page.within('.add-issues-modal') do
        click_link 'Selected issues'

        expect(page).not_to have_selector('.card')
      end
    end

    context 'search' do
      it 'returns issues' do
        page.within('.add-issues-modal') do
          find('.form-control').native.send_keys(issue.title)

          expect(page).to have_selector('.card', count: 1)
        end
      end

      it 'returns no issues' do
        page.within('.add-issues-modal') do
          find('.form-control').native.send_keys('testing search')

          expect(page).not_to have_selector('.card')
        end
      end
    end

    context 'selecing issues' do
      it 'selects single issue' do
        page.within('.add-issues-modal') do
          first('.card').click

          page.within('.nav-links') do
            expect(page).to have_content('Selected issues 1')
          end
        end
      end

      it 'changes button text' do
        page.within('.add-issues-modal') do
          first('.card').click

          expect(first('.add-issues-footer .btn')).to have_content('Add 1 issue')
        end
      end

      it 'changes button text with plural' do
        page.within('.add-issues-modal') do
          all('.card').each do |el|
            el.click
          end

          expect(first('.add-issues-footer .btn')).to have_content('Add 2 issues')
        end
      end

      it 'shows only selected issues on selected tab' do
        page.within('.add-issues-modal') do
          first('.card').click

          click_link 'Selected issues'

          expect(page).to have_selector('.card', count: 1)
        end
      end

      it 'selects all issues' do
        page.within('.add-issues-modal') do
          click_button 'Select all'

          expect(page).to have_selector('.is-active', count: 2)
        end
      end

      it 'un-selects all issues' do
        page.within('.add-issues-modal') do
          click_button 'Select all'

          expect(page).to have_selector('.is-active', count: 2)

          click_button 'Un-select all'

          expect(page).not_to have_selector('.is-active')
        end
      end

      it 'selects all that arent already selected' do
        page.within('.add-issues-modal') do
          first('.card').click

          expect(page).to have_selector('.is-active', count: 1)

          click_button 'Select all'

          expect(page).to have_selector('.is-active', count: 2)
        end
      end

      it 'unselects from selected tab' do
        page.within('.add-issues-modal') do
          first('.card').click

          click_link 'Selected issues'

          first('.card').click

          expect(page).not_to have_selector('.card')
        end
      end
    end

    context 'adding issues' do
      it 'adds to board' do
        page.within('.add-issues-modal') do
          first('.card').click

          click_button 'Add 1 issue'
        end

        page.within(first('.board')) do
          expect(page).to have_selector('.card')
        end
      end

      it 'adds to second list' do
        page.within('.add-issues-modal') do
          first('.card').click

          click_button planning.title

          click_link label.title

          click_button 'Add 1 issue'
        end

        page.within(find('.board:nth-child(2)')) do
          expect(page).to have_selector('.card')
        end
      end
    end
  end
end
