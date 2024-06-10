defmodule Phoenix00.Messages.MessageRepo do
  import Ecto.Query, warn: false
  alias Phoenix00.Messages.Message
  alias Phoenix00.Repo

  def update_status_by_sender_id_and_destinations(transmission_id, recipients, status) do
    Enum.each(recipients, fn recipient -> ensure_messgae_exists(transmission_id, recipient) end)

    updates =
      Repo.all(get_messages_by_sender_id_and_recipients_query(transmission_id, recipients))
      |> Enum.map(
        &Fsmx.transition_changeset(&1, String.to_existing_atom(status), %{}, state_field: :status)
      )
      |> Enum.filter(fn changeset -> changeset.valid? end)

    Repo.transaction(fn -> Enum.map(updates, &Repo.update(&1)) end)
  end

  defp ensure_messgae_exists(transmission_id, recipient) do
    query =
      from message in "messages",
        where: message.transmission == ^transmission_id and message.recipient == ^recipient,
        select: [:status]

    if !Repo.one(query) do
      create_message(%{
        status: :sent,
        recipient: recipient,
        transmission: transmission_id
      })
    end

    Repo.one(query)
  end

  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  defp get_messages_by_sender_id_and_recipients_query(transmission_id, recipients) do
    from message in Message,
      where: message.transmission == ^transmission_id and message.recipient in ^recipients
  end
end
