module Powerbot
  module DiscordEvents
    module Tag
      extend Discordrb::EventContainer

      # Recall tag
      message(start_with: /\?[A-z]/) do |event|
        tag_key = event.message.content[1..-1]

        if tag_key == 'tags'
          tags = Database::Tag.where(channel_id: event.channel.id).all
          next event.channel.send_embed("\u{1F516} **Tags in this channel**") do |embed|
            embed.description = tags.map(&:key).join(', ')
            embed.footer = { text: 'recall a tag with ?tag_name' }
            embed.color = 0xdd2e44
          end if tags.any?
          next event.respond 'No tags in this channel.'
        else
          tag = Database::Tag.search(tag_key, event.channel)
          next event.channel.send_embed("\u{1F516} **#{tag.key}**", tag.embed) if tag
        end

        event.respond '`tag not found`'
      end

      # Create tag
      message(start_with: /\![A-z]/) do |event|
        tag_data = event.message.content[1..-1].split(' ')
        next event.respond('Missing tag content. Format: `!tag_name content`') if tag_data.size == 1

        tag_key = tag_data.first
        tag_text = event.message.content[tag_key.length + 2..-1]

        existing_tag = Database::Tag.search(tag_key, event.channel)
        next event.respond("Tag `#{tag_data.first}` already exists in this channel.") if existing_tag

        Database::Tag.create(
          author_id: event.user.id,
          author_name: event.user.distinct,
          channel_id: event.channel.id,
          key: tag_key,
          text: tag_text
        )

        event.respond "Created tag in #{event.channel.mention}: `#{tag_key}`"
      end

      # Modify tag
      message(start_with: /\~[A-z]/) do |event|
        tag_data = event.message.content[1..-1].split(' ')
        next event.respond('Missing tag content. Format: `~tag_name content`') if tag_data.size == 1

        tag_key = tag_data.first
        tag_text = event.message.content[tag_key.length + 2..-1]

        tag = Database::Tag.search(tag_key, event.channel)
        if tag
          next event.respond 'You can only edit tags you created.' unless tag.author_id == event.user.id
          tag.update(text: tag_text, timestamp: ::Time.now)
          next event.respond "Updated tag: `#{tag.key}`"
        end

        event.respond '`tag not found`'
      end

      # Delete tag
      message(start_with: /\%[A-z]/) do |event|
        tag_key = event.message.content[1..-1]

        tag = Database::Tag.search(tag_key, event.channel)
        if tag
          next event.respond 'You can only delete tags you created.' unless tag.author_id == event.user.id
          tag.destroy
          next event.respond "Deleted tag: `#{tag.key}`"
        end

        event.respond '`tag not found`'
      end
    end
  end
end
