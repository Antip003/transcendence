import Backbone from "backbone";
import PongView from "./views/pong";
import OauthView from "./views/oauth";
import UsersView from "./views/users"
import HomeView from "./views/home";
import SettingsView from "./views/settings";
import pong_game from "./pong_game";

let AppRouter = Backbone.Router.extend({
    initialize: function() {
        this.main = {};
        this.main.el = $("#app_main");

        //  placeholder for chatrooms element
        this.chat = {};
        this.chat.el = $("#app_chat");
    },
    routes: {
        "oauth"     : "oauth",
        "index"     : "home",
        "play"      : "pong",
        "users"     : "users",
        "settings"  : "settings",
        ".*"        : "pong" // 404
    },
    home: function () {
        this.main.view = new HomeView.View();
        this.main.el.html(this.main.view.render().el);
    },
    pong: function () {
        this.main.view = new PongView.View();
        this.main.el.html(this.main.view.render().el);
        pong_game();
    },
    play: function () {
        this.main.view = new OauthView.View();
        this.main.el.html(this.main.view.render().el);
    },
    settings: function () {
        this.main.view = new SettingsView.View();
        this.main.el.html(this.main.view.render().el);
    },
    users: function () {
        this.main.view = new UsersView.View();
        this.main.el.html(this.main.view.render().el);
    }
});

class MainSPA {
    constructor() {
        this.router = new AppRouter;
        console.log(this.router);
        if (Backbone.History.started === false) {
            Backbone.history.start();
        }
    }
}

// load on DOM ready
$(function () {
    new MainSPA;
});

export default MainSPA;
