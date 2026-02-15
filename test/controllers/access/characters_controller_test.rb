require "test_helper"

module Access
  class CharactersControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:four)  # Usuário SEM personagem
      @user_with_character = users(:one)
      @character = game_characters(:one)
      @other_user = users(:two)
      @other_character = game_characters(:two)
    end

    # Authentication
    test "should redirect to root when not logged in on new" do
      get new_character_path
      assert_redirected_to root_path
      assert_equal "Você precisa estar logado para acessar esta página.", flash[:alert]
    end

    test "should redirect to root when not logged in on create" do
      post create_character_path, params: {
        game_character: { nickname: "Test", level: 50, power: 1000 }
      }
      assert_redirected_to root_path
    end

    test "should redirect to root when not logged in on edit" do
      get edit_character_path
      assert_redirected_to root_path
    end

    test "should redirect to root when not logged in on update" do
      patch update_character_path, params: {
        game_character: { nickname: "Updated" }
      }
      assert_redirected_to root_path
    end

    test "should redirect to root when not logged in on destroy" do
      delete destroy_character_path
      assert_redirected_to root_path
    end

    # New Action
    test "should get new when logged in without character" do
      sign_in @user
      get new_character_path
      assert_response :success
      assert_not_nil assigns(:character)
      assert assigns(:character).new_record?
    end

    test "should redirect to edit when logged in with existing character" do
      sign_in @user_with_character
      get new_character_path
      assert_redirected_to edit_character_path
    end

    test "should redirect to edit when user already has character" do
      sign_in @user_with_character
      get new_character_path
      assert_redirected_to edit_character_path
      assert_equal "⚠️ Você já possui um personagem. Use a edição para atualizar.", flash[:alert]
    end

    test "new should build character for current user" do
      sign_in @user
      get new_character_path
      assert_equal @user, assigns(:character).user
    end

    # Create Action
    test "should create character with valid data" do
      sign_in @user

      assert_difference("GameCharacter.count", 1) do
        post create_character_path, params: {
          game_character: {
            nickname: "NewWarrior",
            level: 75,
            power: 15000
          }
        }
      end

      assert_redirected_to profile_path
      assert_equal "✅ Personagem cadastrado com sucesso!", flash[:notice]

      character = GameCharacter.last
      assert_equal "NewWarrior", character.nickname
      assert_equal 75, character.level
      assert_equal 15000, character.power
      assert_equal @user, character.user
    end

    test "should not create character with invalid data" do
      sign_in @user

      assert_no_difference("GameCharacter.count") do
        post create_character_path, params: {
          game_character: {
            nickname: "",  # Invalid: empty nickname
            level: 75,
            power: 15000
          }
        }
      end

      assert_response :unprocessable_entity
      assert_match "Erro ao cadastrar personagem", response.body
    end

    test "should not create character if user already has one" do
      sign_in @user_with_character

      assert_no_difference("GameCharacter.count") do
        post create_character_path, params: {
          game_character: {
            nickname: "AnotherOne",
            level: 50,
            power: 1000
          }
        }
      end

      assert_redirected_to edit_character_path
      assert_equal "⚠️ Você já possui um personagem. Use a edição para atualizar.", flash[:alert]
    end

    test "should not create character with level out of range" do
      sign_in @user

      assert_no_difference("GameCharacter.count") do
        post create_character_path, params: {
          game_character: {
            nickname: "TestChar",
            level: 1000,  # Invalid: > 999
            power: 15000
          }
        }
      end

      assert_response :unprocessable_entity
    end

    test "should not create character with negative power" do
      sign_in @user

      assert_no_difference("GameCharacter.count") do
        post create_character_path, params: {
          game_character: {
            nickname: "TestChar",
            level: 50,
            power: -100  # Invalid: negative
          }
        }
      end

      assert_response :unprocessable_entity
    end

    # Edit Action
    test "should get edit when user has character" do
      sign_in @user_with_character
      get edit_character_path
      assert_response :success
      assert_not_nil assigns(:character)
      assert_equal @character, assigns(:character)
    end

    test "should redirect to new when user has no character on edit" do
      sign_in @user
      get edit_character_path
      assert_redirected_to new_character_path
      assert_equal "⚠️ Você ainda não possui um personagem. Crie um primeiro.", flash[:alert]
    end

    test "edit should show current character data" do
      sign_in @user_with_character
      get edit_character_path
      assert_match @character.nickname, response.body
      assert_match @character.level.to_s, response.body
    end

    # Update Action
    test "should update character with valid data" do
      sign_in @user_with_character

      patch update_character_path, params: {
        game_character: {
          nickname: "UpdatedWarrior",
          level: 80,
          power: 20000
        }
      }

      assert_redirected_to profile_path
      assert_equal "✅ Personagem atualizado com sucesso!", flash[:notice]

      @character.reload
      assert_equal "UpdatedWarrior", @character.nickname
      assert_equal 80, @character.level
      assert_equal 20000, @character.power
    end

    test "should not update character with invalid data" do
      sign_in @user_with_character
      original_nickname = @character.nickname

      patch update_character_path, params: {
        game_character: {
          nickname: "",  # Invalid
          level: 80,
          power: 20000
        }
      }

      assert_response :unprocessable_entity
      assert_match "Erro ao atualizar personagem", response.body

      @character.reload
      assert_equal original_nickname, @character.nickname
    end

    test "should redirect to new when user has no character on update" do
      sign_in @user

      patch update_character_path, params: {
        game_character: { nickname: "Test" }
      }

      assert_redirected_to new_character_path
      assert_equal "⚠️ Você precisa criar um personagem primeiro.", flash[:alert]
    end

    test "should update only nickname" do
      sign_in @user_with_character
      original_level = @character.level
      original_power = @character.power

      patch update_character_path, params: {
        game_character: { nickname: "OnlyNicknameChanged" }
      }

      @character.reload
      assert_equal "OnlyNicknameChanged", @character.nickname
      assert_equal original_level, @character.level
      assert_equal original_power, @character.power
    end

    test "should only update permitted parameters" do
      sign_in @user_with_character
      original_user = @character.user

      patch update_character_path, params: {
        game_character: {
          nickname: "Updated",
          user_id: users(:one).id  # Should not be permitted
        }
      }

      @character.reload
      assert_equal original_user, @character.user
    end

    # Destroy Action
    test "should destroy character" do
      sign_in @user_with_character

      assert_difference("GameCharacter.count", -1) do
        delete destroy_character_path
      end

      assert_redirected_to profile_path
      assert_equal "🗑️ Personagem removido com sucesso.", flash[:notice]
    end

    test "should handle destroy when no character exists" do
      sign_in @user

      assert_no_difference("GameCharacter.count") do
        delete destroy_character_path
      end

      assert_redirected_to profile_path
      assert_equal "⚠️ Você não possui um personagem para remover.", flash[:alert]
    end

    test "user cannot destroy another user's character" do
      # user_with_character possui um personagem
      sign_in @user  # Login como usuário sem personagem

      # Criar um personagem para @user
      character = @user.create_game_character!(
        nickname: "MyChar",
        level: 50,
        power: 1000
      )

      # Verificar que só pode deletar o próprio
      assert_difference("GameCharacter.count", -1) do
        delete destroy_character_path
      end

      # O personagem de @user foi deletado
      assert_nil GameCharacter.find_by(id: character.id)
      # O personagem de @user_with_character ainda existe
      assert_not_nil GameCharacter.find_by(id: @character.id)
    end

    # Integration Tests
    test "complete character lifecycle" do
      sign_in @user

      # 1. Create character
      post create_character_path, params: {
        game_character: {
          nickname: "TestLifecycle",
          level: 1,
          power: 100
        }
      }
      assert_redirected_to profile_path

      character = @user.reload.game_character
      assert_not_nil character

      # 2. Edit character
      get edit_character_path
      assert_response :success

      # 3. Update character
      patch update_character_path, params: {
        game_character: {
          level: 50,
          power: 5000
        }
      }
      assert_redirected_to profile_path

      character.reload
      assert_equal 50, character.level
      assert_equal 5000, character.power

      # 4. Destroy character
      delete destroy_character_path
      assert_redirected_to profile_path

      assert_nil @user.reload.game_character
    end
  end
end
