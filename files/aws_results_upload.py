#!/usr/bin/python3
"""Uploads old run results to Amazon S3."""

import argparse
import collections
import configparser
import datetime
import logging
import os
import os.path
import time

from typing import Deque, List, Sequence

import s3put

_GRADE_ROOT = '/var/lib/omegaup/grade'


def _upload(run_id: int, s3client: s3put.S3, dry_run: bool = False) -> bool:
    run_path = os.path.join(
        _GRADE_ROOT,
        '%02d/%02d/%d' % (run_id % 100, (run_id // 100) % 100, run_id))
    assert os.path.isdir(run_path)

    if dry_run:
        return True

    # Files to upload.
    for filename in ('files.zip', 'details.json', 'logs.txt.gz',
                     'tracing.json.gz'):
        path = os.path.join(run_path, filename)
        if not os.path.exists(path):
            continue
        try:
            s3client.put(path=path, filename='/%d/%s' % (run_id, filename))
            os.unlink(path)
        except KeyboardInterrupt:
            raise
        except:  # pylint: disable=bare-except
            logging.exception('Failed to upload %d: %s', run_id, path)
            time.sleep(2)
            return False

    os.rmdir(run_path)
    return True


def _format_delta(seconds: float) -> str:
    seconds = int(seconds)
    hours = seconds // 3600
    seconds %= 3600
    minutes = seconds // 60
    seconds %= 60
    return '%02d:%02d:%02d' % (hours, minutes, seconds)


def _get_runs(last_ctime: int) -> Sequence[int]:
    runs: List[int] = []
    for i in range(100):
        for j in range(100):
            parent_dir = os.path.join(_GRADE_ROOT, '%02d/%02d' % (i, j))
            for run_id in os.listdir(parent_dir):
                try:
                    stinfo = os.stat(os.path.join(parent_dir, run_id))
                    if stinfo.st_ctime >= last_ctime:
                        continue
                    runs.append(int(run_id))
                except ValueError:
                    pass
    runs.sort()
    return runs


def _log_progress(start_time: float, times: Deque[float], runs: Sequence[int],
                  uploaded: int) -> None:
    done_rate = len(times) / (times[-1] - times[0])
    remaining_time = (len(runs) - uploaded) / done_rate
    done_ratio = 1.0 * uploaded / len(runs)
    percent_done = 100 * done_ratio
    logging.info('%d/%d (%.2f %%) %.2f/sec, %s elapsed, %s remaining',
                 uploaded, len(runs), percent_done, done_rate,
                 _format_delta(time.time() - start_time),
                 _format_delta(remaining_time))


def _main() -> None:
    parser = argparse.ArgumentParser()
    logging_args = parser.add_argument_group('Logging')
    logging_args.add_argument('--quiet',
                              '-q',
                              action='store_true',
                              help='Disables logging')
    logging_args.add_argument('--verbose',
                              '-v',
                              action='store_true',
                              help='Enables verbose logging')
    logging_args.add_argument('--logfile',
                              type=str,
                              default=None,
                              help='Enables logging to a file')

    parser.add_argument('--aws-username', type=str, default='omegaup-backups')
    parser.add_argument('--aws-config',
                        type=str,
                        default='/etc/omegaup/grader/aws_credentials')
    parser.add_argument('--days-to-keep', type=int, default=14)
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()

    aws_config = configparser.ConfigParser()
    aws_config.read([args.aws_config])

    logging.basicConfig(
        filename=args.logfile,
        format='%%(asctime)s:%s:%%(message)s' % parser.prog,
        level=(logging.DEBUG if args.verbose else
               logging.INFO if not args.quiet else logging.ERROR))

    last_ctime = (datetime.datetime.now() -
                  datetime.timedelta(days=args.days_to_keep)).timestamp()
    runs = _get_runs(int(last_ctime))

    logging.info('Going to upload %d runs in the [%d, %d] range', len(runs),
                 runs[0], runs[-1])

    start_time = time.time()
    times: Deque[float] = collections.deque([time.time()], maxlen=1000)
    errors: List[int] = []
    uploaded = 0

    s3client = s3put.S3(aws_access_key=aws_config.get(args.aws_username,
                                                      'aws_access_key_id'),
                        secret_access_key=aws_config.get(
                            args.aws_username, 'aws_secret_access_key'),
                        bucket='omegaup-runs')

    for i, run_id in enumerate(runs):
        try:
            if _upload(run_id, s3client, dry_run=args.dry_run):
                uploaded += 1
            else:
                errors.append(run_id)
        except KeyboardInterrupt:
            break
        times.append(time.time())
        if i % 100 == 0:
            _log_progress(start_time, times, runs, uploaded)

    for retry_round in range(10):
        if not errors:
            break
        current_errors = errors
        errors.clear()
        logging.info('Retrying failed runs... round %d: %s', retry_round + 1,
                     ', '.join(str(x) for x in current_errors))
        for run_id in current_errors:
            try:
                if _upload(run_id, s3client, dry_run=args.dry_run):
                    uploaded += 1
                else:
                    errors.append(run_id)
            except KeyboardInterrupt:
                break

    _log_progress(start_time, times, runs, uploaded)


if __name__ == '__main__':
    _main()
