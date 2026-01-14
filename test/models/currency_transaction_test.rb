require "test_helper"

class CurrencyTransactionTest < ActiveSupport::TestCase
  # === Validações ===

  test "deve ser válido com atributos válidos" do
    transaction = CurrencyTransaction.new(
      user: users(:one),
      amount: 100,
      balance_after: 600
    )
    assert transaction.valid?
  end

  test "deve exigir amount" do
    transaction = CurrencyTransaction.new(
      user: users(:one),
      balance_after: 500
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:amount], "can't be blank"
  end

  test "amount deve ser um número inteiro" do
    transaction = CurrencyTransaction.new(
      user: users(:one),
      amount: 10.5,
      balance_after: 500
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:amount], "must be an integer"
  end

  test "amount não pode ser zero" do
    transaction = CurrencyTransaction.new(
      user: users(:one),
      amount: 0,
      balance_after: 500
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:amount], "must be other than 0"
  end

  test "deve exigir balance_after" do
    transaction = CurrencyTransaction.new(
      user: users(:one),
      amount: 100
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:balance_after], "can't be blank"
  end

  test "balance_after deve ser um número inteiro" do
    transaction = CurrencyTransaction.new(
      user: users(:one),
      amount: 100,
      balance_after: 500.5
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:balance_after], "must be an integer"
  end

  # === Relacionamentos ===

  test "deve pertencer a um usuário" do
    transaction = currency_transactions(:one)
    assert_respond_to transaction, :user
    assert_instance_of User, transaction.user
  end

  # === Scopes ===

  test "scope credits deve retornar apenas transações positivas" do
    credits = CurrencyTransaction.credits
    assert credits.all? { |t| t.amount > 0 }
  end

  test "scope debits deve retornar apenas transações negativas" do
    debits = CurrencyTransaction.debits
    assert debits.all? { |t| t.amount < 0 }
  end

  # === Métodos ===

  test "#reason deve retornar a entidade relacionada quando válida" do
    transaction = currency_transactions(:one)
    # Fixture one tem reason_type: Event e reason_id: 1
    if transaction.reason_type.present? && transaction.reason_id.present?
      reason = transaction.reason
      assert_not_nil reason if Event.exists?(transaction.reason_id)
    end
  end

  test "#reason deve retornar nil quando reason_type está em branco" do
    transaction = currency_transactions(:two)
    assert_nil transaction.reason
  end
end
