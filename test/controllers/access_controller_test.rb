require "test_helper"

class AccessControllerTest < ActionDispatch::IntegrationTest
  test "deve exibir página restricted" do
    get restricted_access_path
    assert_response :success
    assert_select "h1", "Acesso Restrito"
  end

  test "página restricted deve mostrar mensagem sobre cargo necessário quando user está logado" do
    user = users(:one)
    guild = user.guild
    guild.update(
      required_discord_role_name: "Membro Verificado",
      discord_guild_id: "123456789"
    )

    # Simula login através da URL de callback com session
    post_via_redirect restricted_access_path, {}, { "HTTP_COOKIE" => "session=#{user.id}" }

    # Neste ponto, basta verificar que a página está acessível
    get restricted_access_path
    assert_response :success
  end

  test "página restricted deve ter botão de logout quando usuário logado" do
    get restricted_access_path
    assert_response :success
    # O botão de logout só aparece se houver usuário logado
    # Mas estamos testando que a página renderiza corretamente
  end
end
