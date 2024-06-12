defmodule Phoenix00.Messages.EmailRepo do
  # use Phoenix00, :repository
  import Ecto.Query, warn: false
  alias Phoenix00.Repo
  alias Phoenix00.Messages.Email

  def list_emails(lim \\ 10, off \\ 0, order \\ [desc: :updated_at]) do
    Email |> limit(^lim) |> offset(^off) |> order_by(^order) |> Repo.all()
  end

  def get_email!(id), do: Repo.get!(Email, id)

  def get_email_by_aws_id(aws_message_id) do
    Repo.get_by(Email, sender_id: aws_message_id)
  end

  def email_count() do
    Repo.aggregate(Email, :count, :id)
  end

  def create_email(attrs \\ %{}) do
    change_email(%Email{}, attrs)
    |> Repo.insert()
  end

  # def create_or_find_email(attrs) do
  #   query =
  #     from r in Recipient,
  #       where: r.destination == ^attrs.destination

  #   if !Repo.one(query) do
  #     create_recipient(attrs)
  #   end

  #   Repo.one(query)
  # end

  def find_or_create_email_record_by_ses_message(message) do
    case get_email_by_aws_id(message["mail"]["messageId"]) do
      nil ->
        {:ok, email} =
          create_email(%{
            sender_id: message["mail"]["messageId"],
            to: List.flatten([Enum.at(message["mail"]["commonHeaders"]["to"], 0)]),
            from: Enum.at(message["mail"]["commonHeaders"]["from"], 0),
            status: get_status_from_event_type(message["eventType"]),
            email_id: message["mail"]["messageId"],
            body:
              "<h1>This message was not sent via 00, therefore we did not collect the body.</h1>"
          })

        email

      email ->
        email
    end
  end

  def update_email(%Email{} = email, attrs) do
    change_email(email, attrs)
    |> Repo.update()
  end

  def update_email(attrs) do
    change_email(%Email{}, attrs)
    |> Repo.update()
  end

  def delete_email(%Email{} = email) do
    Repo.delete(email)
  end

  def change_email(%Email{} = email, attrs \\ %{}) do
    Email.changeset(email, attrs)
  end

  defp get_status_from_event_type(event_type) do
    case event_type do
      "Bounce" -> "bounced"
      "Complaint" -> "complained"
      "Send" -> "sent"
      "Pending" -> "pending"
      "Delivery" -> "delivered"
    end
  end
end
