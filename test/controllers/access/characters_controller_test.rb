require "test_helper"

module Access
  class CharactersControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:four)
      @user_with_character = users(:one)
      @character = game_characters(:one)
      @other_character = game_characters(:two)
    end

    test "should redirect to root when not logged in on new" do
      get new_character_path
      assert_redirected_to root_path
    end

    test "should redirect to root when not logged in on create" do
      post characters_path, params: { game_character: { nickname: "Test", level: 50, power: 1000 } }
      assert_redirected_to root_path
    end

    test "should redirect to root when not logged in on edit/update/destroy" do
      get edit_character_path(@character)
      assert_redirected_to root_path

      patch character_path(@character), params: { game_character: { nickname: "Updated" } }
      assert_redirected_to root_path

      delete character_path(@character)
      assert_redirected_to root_path
    end

    test "should create multiple characters for same user" do
      sign_in @user

      assert_difference("GameCharacter.count", 2) do
        post characters_path, params: {
          game_character: { nickname: "AA", level: 10, power: 1000 }
        }
        post characters_path, params: {
          game_character: { nickname: "BB", level: 20, power: 2000 }
        }
      end

      assert_equal 2, @user.reload.game_characters.count
      assert_equal 1, @user.game_characters.where(is_primary: true).count
    end

    test "first created character should be primary" do
      sign_in @user

      post characters_path, params: {
        game_character: { nickname: "Primeiro", level: 10, power: 1000 }
      }

      assert GameCharacter.last.is_primary?
    end

    test "should create character following guild template custom fields" do
      @user.guild.update!(
        character_template: [
          { key: "nickname", label: "Nickname", field_type: "string", required: true },
          { key: "level", label: "Nível", field_type: "integer", required: true },
          { key: "power", label: "Poder", field_type: "integer", required: true },
          { key: "classe", label: "Classe", field_type: "string", required: true }
        ]
      )
      sign_in @user

      assert_difference("GameCharacter.count", 1) do
        post characters_path, params: {
          game_character: {
            nickname: "TemplateChar",
            level: 50,
            power: 9000,
            character_data: { classe: "Mago" }
          }
        }
      end

      assert_redirected_to profile_path
      assert_equal "Mago", GameCharacter.last.character_data["classe"]
    end

    test "should not create character when required template field is missing" do
      @user.guild.update!(
        character_template: [
          { key: "nickname", label: "Nickname", field_type: "string", required: true },
          { key: "level", label: "Nível", field_type: "integer", required: true },
          { key: "power", label: "Poder", field_type: "integer", required: true },
          { key: "classe", label: "Classe", field_type: "string", required: true }
        ]
      )
      sign_in @user

      assert_no_difference("GameCharacter.count") do
        post characters_path, params: {
          game_character: {
            nickname: "TemplateChar",
            level: 50,
            power: 9000,
            character_data: {}
          }
        }
      end

      assert_response :unprocessable_entity
    end

    test "should edit own character" do
      sign_in @user_with_character
      get edit_character_path(@character)
      assert_response :success
    end

    test "should not edit character from another user" do
      sign_in @user_with_character
      get edit_character_path(@other_character)
      assert_redirected_to profile_path
      assert_equal "⚠️ Personagem não encontrado.", flash[:alert]
    end

    test "should update own character" do
      sign_in @user_with_character

      patch character_path(@character), params: {
        game_character: { nickname: "UpdatedWarrior", level: 88, power: 20000 }
      }

      assert_redirected_to profile_path
      @character.reload
      assert_equal "UpdatedWarrior", @character.nickname
      assert_equal 88, @character.level
      assert_equal 20000, @character.power
    end

    test "should switch primary character on update" do
      sign_in @user_with_character
      second = @user_with_character.game_characters.create!(
        nickname: "Secundario",
        level: 30,
        power: 500,
        is_primary: false
      )

      patch character_path(second), params: {
        game_character: { is_primary: true, nickname: second.nickname, level: second.level, power: second.power }
      }

      assert_redirected_to profile_path
      assert second.reload.is_primary?
      assert_not @character.reload.is_primary?
    end

    test "should destroy own character" do
      sign_in @user_with_character

      assert_difference("GameCharacter.count", -1) do
        delete character_path(@character)
      end

      assert_redirected_to profile_path
    end
  end
end
