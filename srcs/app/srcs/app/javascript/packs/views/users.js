import Backbone from "backbone";
import _ from "underscore";
import UserCollection from "../models/users";
import Utils from "../helpers/utils";

const UsersView = {};

$(function () {
	UsersView.SingleUserView = Backbone.View.extend({
        template: _.template($('#singleuser-template').html()),
        events: {
            "keypress .displayname" : "updateOnEnter"
        },
        tagName: "tr",
        initialize: function () {
            this.listenTo(this.model, 'change', this.render);
            this.listenTo(this.model, 'destroy', this.remove);
            this.listenTo(this.model, 'error', this.onerror);
        },
        updateOnEnter: function (e) {
            if (e.keyCode !== 13) return;

            let newdisplayname = this.input.val();
            if (this.model.get('displayname') !== newdisplayname)
            {
                e.preventDefault();
                e.stopPropagation();
                this.model.save({displayname: newdisplayname},
                    {patch: true, success: this.onsuccess});
            }
        },
        onerror: function (model, response) {
            if (response.responseJSON == null) //  true for undefined too
                Utils.app_alert('danger', {msg: 'No response from API'});
            else
                Utils.app_alert('danger', {json: response.responseJSON});
            this.model.attributes = this.model.previousAttributes();
            this.render();
        },
        onsuccess: function () {
            Utils.app_alert('success', {msg: 'Displayname has been changed'});
        },
        render: function() {
            this.$el.html(this.template(this.model.toJSON()));
            this.input = this.$('.displayname');
            let model = this.model;
            this.$('.user_icon').on("error",
                function () { Utils.replaceavatar(this, model); });
            return this;
        }
    });

	UsersView.View = Backbone.View.extend({
		template: _.template($('#users-template').html()),
		events: {
		    "click #refresh-button" :   "refresh"
        },
		initialize: function () {
		    this.collection = new UserCollection;
		    this.listenTo(this.collection, 'add', this.addOne);
		    this.listenTo(this.collection, 'reset', this.addAll);
            this.collection.fetch({reset: true, error: this.onerror});
        },
		addOne: function (user) {
            user.view = new UsersView.SingleUserView({model: user});
            this.$("tbody").append(user.view.render().el);
        },
        addAll: function () {
            this.collection.each(this.addOne, this);
        },
        refresh: function () {
            this.collection.fetch({
                success: function () {Utils.app_alert('success', {msg: 'Up to date'});},
                error: this.onerror});
        },
        onerror: function () {
            Utils.app_alert('danger', {msg: 'Users fetch from API failed'});
        },
		render: function () {
			this.$el.html(this.template());
			this.addAll();
			return this;
		}
	});
});

export default UsersView;
