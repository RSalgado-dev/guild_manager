module Access
  # Controller para gerenciar personagens do jogo
  class CharactersController < AccessController
    before_action :load_user_context
    before_action :load_template_fields
    before_action :load_character, only: [ :edit, :update, :destroy ]
    before_action :ensure_character!, only: [ :edit, :update, :destroy ]

    def new
      @character = current_user.game_characters.build
    end

    def create
      @character = current_user.game_characters.build(character_params)
      @character.character_data = sanitized_character_data

      if @character.save
        redirect_to profile_path, notice: "✅ Personagem cadastrado com sucesso!"
      else
        flash.now[:alert] = "❌ Erro ao cadastrar personagem: #{@character.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      @character.assign_attributes(character_params)
      @character.character_data = sanitized_character_data(default: @character.character_data || {})

      if @character.save
        redirect_to profile_path, notice: "✅ Personagem atualizado com sucesso!"
      else
        flash.now[:alert] = "❌ Erro ao atualizar personagem: #{@character.errors.full_messages.join(', ')}"
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @character.destroy
        redirect_to profile_path, notice: "🗑️ Personagem removido com sucesso."
      else
        redirect_to profile_path, alert: "❌ Erro ao remover personagem."
      end
    end

    private

    def character_params
      params.require(:game_character).permit(:nickname, :level, :power, :is_primary, :status_screenshot)
    end

    def load_character
      @character = current_user.game_characters.find_by(id: params[:id])
    end

    def load_template_fields
      @template_fields = @guild.character_template_fields
    end

    def ensure_character!
      return if @character.present?

      redirect_to profile_path, alert: "⚠️ Personagem não encontrado."
    end

    def sanitized_character_data(default: {})
      raw_values = params.dig(:game_character, :character_data)
      return default unless raw_values.is_a?(ActionController::Parameters) || raw_values.is_a?(Hash)

      allowed_keys = @template_fields.reject { |field| field["system"] }.map { |field| field["key"] }
      raw_hash = raw_values.respond_to?(:to_unsafe_h) ? raw_values.to_unsafe_h : raw_values.to_h

      raw_hash.slice(*allowed_keys).transform_values { |value| value.is_a?(String) ? value.strip : value }
    end
  end
end
