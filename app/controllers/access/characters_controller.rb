module Access
  # Controller para gerenciar personagens do jogo
  class CharactersController < AccessController
    before_action :load_user_context
    before_action :load_character, only: [ :edit, :update, :destroy ]
    before_action :prevent_duplicate_character, only: [ :new, :create ]

    def new
      # Formulário para criar personagem do jogo
      @character = current_user.build_game_character
    end

    def create
      # Cria personagem do jogo
      @character = current_user.build_game_character(character_params)

      if @character.save
        redirect_to profile_path, notice: "✅ Personagem cadastrado com sucesso!"
      else
        flash.now[:alert] = "❌ Erro ao cadastrar personagem: #{@character.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      # Formulário para editar personagem do jogo
      redirect_to new_character_path, alert: "⚠️ Você ainda não possui um personagem. Crie um primeiro." unless @character
    end

    def update
      # Atualiza personagem do jogo
      unless @character
        redirect_to new_character_path, alert: "⚠️ Você precisa criar um personagem primeiro."
        return
      end

      if @character.update(character_params)
        redirect_to profile_path, notice: "✅ Personagem atualizado com sucesso!"
      else
        flash.now[:alert] = "❌ Erro ao atualizar personagem: #{@character.errors.full_messages.join(', ')}"
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      # Deleta personagem do jogo
      unless @character
        redirect_to profile_path, alert: "⚠️ Você não possui um personagem para remover."
        return
      end

      if @character.destroy
        redirect_to profile_path, notice: "🗑️ Personagem removido com sucesso."
      else
        redirect_to profile_path, alert: "❌ Erro ao remover personagem."
      end
    end

    private

    def character_params
      # Permite apenas campos do personagem
      params.require(:game_character).permit(:nickname, :level, :power, :status_screenshot)
    end

    def load_character
      @character = current_user.game_character
    end

    def prevent_duplicate_character
      if current_user.game_character.present?
        redirect_to edit_character_path, alert: "⚠️ Você já possui um personagem. Use a edição para atualizar."
      end
    end
  end
end
