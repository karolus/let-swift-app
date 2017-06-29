//
//  SpeakersViewControllerViewModel.swift
//  LetSwift
//
//  Created by Kinga Wilczek on 14.06.2017.
//  Copyright © 2017 Droids On Roids. All rights reserved.
//

import Foundation
import Alamofire

final class SpeakersViewControllerViewModel {

    private enum Constants {
        static let speakersOrderCurrent = "current"
        static let speakersOrderLatest = "recent"
        static let speakersPerPage = 10
        static let firstPage = 1
    }

    private let disposeBag = DisposeBag()
    private var currentPage = Constants.firstPage
    private var totalPage = -1
    private var pendingRequest: Request?
    private var searchQuery = ""

    var speakerLoadDataRequestObservable = Observable<Void>()
    var tableViewStateObservable: Observable<AppContentState>
    var checkIfLastSpeakerObservable = Observable<Int>(-1)
    var tryToLoadMoreDataObservable = Observable<Void>()
    var noMoreSpeakersToLoadObservable = Observable<Void>()
    var errorOnLoadingMoreSpeakersObservable = Observable<Void>()
    var refreshDataObservable = Observable<Void>()
    var speakerCellDidTapWithIndexObservable = Observable<Int>(-1)
    var latestSpeakerCellDidTapWithIndexObservable = Observable<Int>(-1)
    var searchQueryObservable = Observable<String>("")
    var searchBarShouldResignFirstResponderObservable = Observable<Void>()

    weak var delegate: SpeakersViewControllerDelegate?
    var speakers = [Speaker]().bindable
    var latestSpeakers = [Speaker]().bindable

    init(delegate: SpeakersViewControllerDelegate?) {
        self.delegate = delegate
        tableViewStateObservable = Observable<AppContentState>(.loading)

        setup()
    }

    private func setup() {
        speakerLoadDataRequestObservable.subscribeNext { [weak self] in
            guard self?.pendingRequest == nil else { return }

            self?.tableViewStateObservable.next(.loading)
            self?.loadInitialData()
        }
        .add(to: disposeBag)

        checkIfLastSpeakerObservable.subscribeNext { [weak self] index in
            guard let weakSelf = self, weakSelf.speakers.values.count - 1 == index else { return }

            weakSelf.loadMoreData()
        }
        .add(to: disposeBag)

        tryToLoadMoreDataObservable.subscribeNext { [weak self] in
            self?.loadMoreData()
        }
        .add(to: disposeBag)

        refreshDataObservable.subscribeNext { [weak self] in
            guard self?.pendingRequest == nil else { return }

            self?.loadInitialData()
        }
        .add(to: disposeBag)

        speakerCellDidTapWithIndexObservable.subscribeNext { [weak self] index in
            //TODO: send id of speaker
            self?.delegate?.presentSpeakerDetailsScreen()
        }
        .add(to: disposeBag)

        latestSpeakerCellDidTapWithIndexObservable.subscribeNext { [weak self] index in
            //TODO: send id of latest speaker
            self?.delegate?.presentSpeakerDetailsScreen()
        }
        .add(to: disposeBag)

        searchQueryObservable.subscribeNext { [weak self] query in
            self?.searchQuery = query
        }
        .add(to: disposeBag)
    }

    private func loadInitialData() {
        pendingRequest = NetworkProvider.shared.speakersList(with: Constants.firstPage, perPage: Constants.speakersPerPage, query: searchQuery, order: Constants.speakersOrderCurrent) { [weak self] response in
            guard let weakSelf = self else { return }

            switch response {
            case let .success(responeObject):
                weakSelf.speakers.values = []
                weakSelf.speakers.append(responeObject.elements)
                weakSelf.totalPage = responeObject.page.pageCount
                weakSelf.currentPage = Constants.firstPage

                if weakSelf.searchQuery.isEmpty || weakSelf.latestSpeakers.values.isEmpty {
                    weakSelf.loadLatestSpeakers()
                } else {
                    weakSelf.tableViewStateObservable.next(.content)
                    weakSelf.pendingRequest = nil
                    weakSelf.refreshDataObservable.complete()
                }
            case .error:
                weakSelf.tableViewStateObservable.next(.error)
                weakSelf.refreshDataObservable.complete()
                weakSelf.pendingRequest = nil
            }
        }
    }

    private func loadLatestSpeakers() {
        NetworkProvider.shared.speakersList(with: Constants.firstPage, perPage: Constants.speakersPerPage, order: Constants.speakersOrderLatest) { [weak self] response in
            switch response {
            case let .success(responseLatest):
                self?.latestSpeakers.append(responseLatest.elements)
                self?.tableViewStateObservable.next(.content)
            case .error:
                self?.tableViewStateObservable.next(.error)
            }
            self?.refreshDataObservable.complete()
            self?.pendingRequest = nil
        }
    }

    private func loadMoreData() {
        guard pendingRequest == nil else { return }

        guard currentPage < totalPage || totalPage == -1 else {
            noMoreSpeakersToLoadObservable.next()
            return
        }

        pendingRequest = NetworkProvider.shared.speakersList(with: currentPage + 1, perPage: Constants.speakersPerPage, query: searchQuery, order: Constants.speakersOrderCurrent) { [weak self] response in
            switch response {
            case let .success(responeObject):
                self?.currentPage += 1
                self?.speakers.append(responeObject.elements)
                self?.totalPage = responeObject.page.pageCount
            default:
                self?.errorOnLoadingMoreSpeakersObservable.next()
            }

            self?.pendingRequest = nil
        }
    }
}
