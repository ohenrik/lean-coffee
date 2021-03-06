angular.module "lean-coffee"
  .service "topicsService", ($rootScope, $resource, $pusher, Topic) ->
    @to_talk_about = []
    @talking_about = []
    @talked_about  = []

    pusher = $pusher(pusherClient)

    channel = pusher.subscribe 'channel'

    channel.bind 'new_topic', (topic) =>
      @addTopic new Topic(topic)

    channel.bind 'updated_topic', (topic) =>
      @updateTopic new Topic(topic)

    @load = =>
      topics = Topic.query =>
        @sort()

        for topic in topics
          switch topic.status
            when "to_talk_about"
              @to_talk_about.unshift topic
            when "talking_about"
              @talking_about.unshift topic
            when "talked_about"
              @talked_about.unshift topic

    @create = (attributes) =>
      topic = new Topic(attributes)
      topic.$save()
        .then (topic) =>
          @addTopic(topic)

    @addTopic = (topic) =>
      switch topic.status
        when "to_talk_about"
          @to_talk_about.unshift topic
        when "talking_about"
          @talking_about.unshift topic
        when "talked_about"
          @talked_about.unshift topic

    @updateTopic = (topic) =>
      topic = _.find @to_talk_about, (t) => t.id == topic.id
      topic.$get()

    @voteFor = (topic) =>
      topic.votes += 1
      topic.$update()

    @move = (topic, lane) =>
      topic.status = lane
      topic.$update()

    @destroy = (topic) =>
      topic.$delete()

      for list in [@to_talk_about, @talking_about, @talked_about]
        index = _.indexOf(list, topic)
        list.splice(index, 1)

    @sort = =>
      for list in [@to_talk_about, @talking_about, @talked_about]
        list.sort (a, b) => b.votes - a.votes

    @load()

    this
